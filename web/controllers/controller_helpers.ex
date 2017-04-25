defmodule Coherence.ControllerHelpers do
  @moduledoc """
  Common helper functions for Coherence Controllers.
  """
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2, put_layout: 2, put_view: 2]
  import Plug.Conn, only: [halt: 1]

  alias Coherence.{ConfirmableService, RememberableService, TrackableService, Messages}
  alias Coherence.Config

  require Logger

  @type schema :: Ecto.Schema.t
  @type changeset :: Ecto.Changeset.t
  @type schema_or_error :: schema | {:error, changeset}
  @type conn :: Plug.Conn.t
  @type params :: Map.t

  @doc """
  Put LayoutView

  Adds Config.layout if set.
  """
  @spec layout_view(Plug.Conn.t, Keyword.t) :: Plug.Conn.t
  def layout_view(conn, opts) do
    layout =
      case opts[:layout] || Config.layout() do
        nil -> {Coherence.LayoutView, "app.html"}
        layout -> layout
      end

    conn
    |> put_layout(layout)
    |> set_view(opts)
  end

  @doc """
  Set view plug
  """
  @spec set_view(Plug.Conn.t, Keyword.t) :: Plug.Conn.t
  def set_view(conn, opts) do
    case opts[:view] do
      nil -> conn
      view -> put_view conn, view
    end
  end

  @doc """
  Get the Router.Helpers module for the project..

  Returns the projects Router.Helpers module.
  """
  @spec router_helpers() :: module
  def router_helpers do
    Module.concat(Config.router(), Helpers)
  end

  @doc """
  Get the configured logged_out_url.
  """
  @spec logged_out_url(Plug.Conn.t) :: String.t
  def logged_out_url(conn) do
    Config.logged_out_url || router_helpers().session_path(conn, :new)
  end

  @doc """
  Get the configured logged_in_url.
  """
  @spec logged_in_url(Plug.Conn.t) :: String.t
  def logged_in_url(_conn) do
    Config.logged_in_url || "/"
  end

  @doc """
  Get a random string of given length.

  Returns a random url safe encoded64 string of the given length.
  Used to generate tokens for the various modules that require unique tokens.
  """
  @spec random_string(integer) :: binary
  def random_string(length) do
    length
    |> :crypto.strong_rand_bytes
    |> Base.url_encode64
    |> binary_part(0, length)
  end

  @doc """
  Test if a datetime has expired.

  Convert the datetime from Ecto.DateTime format to Timex format to do
  the comparison given the time during in opts.

  ## Examples

      expired?(user.expire_at, days: 5)
      expired?(user.expire_at, minutes: 10)

      iex> Ecto.DateTime.utc
      ...> |> Coherence.ControllerHelpers.expired?(days: 1)
      false

      iex> Ecto.DateTime.utc
      ...> |> Coherence.ControllerHelpers.shift(days: -2)
      ...> |> Ecto.DateTime.cast!
      ...> |> Coherence.ControllerHelpers.expired?(days: 1)
      true
  """
  @spec expired?(nil | struct, Keyword.t) :: boolean
  def expired?(nil, _), do: true
  def expired?(datetime, opts) do
    not Timex.before?(Timex.now, shift(datetime, opts))
  end

  @doc """
  Shift a Ecto.DateTime.

  ## Examples

      iex> Ecto.DateTime.cast!("2016-10-10 10:10:10")
      ...> |> Coherence.ControllerHelpers.shift(days: -2)
      ...> |> Ecto.DateTime.cast!
      ...> |> to_string
      "2016-10-08 10:10:10"
  """
  @spec shift(struct, Keyword.t) :: struct
  def shift(datetime, opts) do
    datetime
    |> Ecto.DateTime.to_erl
    |> Timex.to_datetime
    |> Timex.shift(opts)
  end

  @doc """
  Log an error message when lockable update fails.
  """
  @spec lockable_failure(Ecto.Changeset.t) :: :ok
  def lockable_failure(changeset) do
    Logger.error "Failed to update lockable attributes " <> inspect(changeset.errors)
  end

  @doc """
  Send a user email.

  Sends a user email given the module, model, and url. Logs the email for
  debug purposes.

  Note: This function uses an apply to avoid compile warnings if the
  mailer is not selected as an option.
  """
  @spec send_user_email(atom, Ecto.Schema.t, String.t) :: any
  def send_user_email(fun, model, url) do
    email = apply(Module.concat(Config.module, Coherence.UserEmail), fun, [model, url])
    Logger.debug fn -> "#{fun} email: #{inspect email}" end
    apply(Module.concat(Config.module, Coherence.Mailer), :deliver, [email])
  end

  @doc """
  Send confirmation email with token.

  If the user supports confirmable, generate a token and send the email.
  """
  @spec send_confirmation(Plug.Conn.t, Ecto.Schema.t, module) :: Plug.Conn.t
  def send_confirmation(conn, user, user_schema) do
    if user_schema.confirmable? do
      token = random_string 48
      url = router_helpers().confirmation_url(conn, :edit, token)
      Logger.debug "confirmation email url: #{inspect url}"
      dt = Ecto.DateTime.utc
      user
      |> user_schema.changeset(%{confirmation_token: token,
        confirmation_sent_at: dt,
        current_password: user.password})
      |> Config.repo.update!

      send_user_email :confirmation, user, url
      conn
      |> put_flash(:info, Messages.backend().confirmation_email_sent())
    else
      conn
      |> put_flash(:info, Messages.backend().registration_created_successfully())
    end
  end

  #############
  # User Schema

  @doc """
  Confirm a user account.

  Adds the `:confirmed_at` datetime field on the user model and updates the database
  """
  @spec confirm!(Ecto.Schema.t) :: schema_or_error
  def confirm!(user) do
    changeset = ConfirmableService.confirm(user)
    if ConfirmableService.confirmed? user do
      changeset = Ecto.Changeset.add_error changeset, :confirmed_at, Messages.backend().already_confirmed()
      {:error, changeset}
    else
      Config.repo.update changeset
    end
  end

  @doc """
  Lock a use account.

  Sets the `:locked_at` field on the user model to the current date and time unless
  provided a value for the optional parameter.

  You can provide a date in the future to override the configured lock expiry time. You
  can set this data far in the future to do a pseudo permanent lock.
  """
  @spec lock!(Ecto.Schema.t, struct) :: schema_or_error
  def lock!(user, locked_at \\ Ecto.DateTime.utc) do
    user_schema = Config.user_schema
    changeset = user_schema.lock user, locked_at
    if user_schema.locked?(user) do
      changeset = Ecto.Changeset.add_error changeset, :locked_at, Messages.backend().already_locked()
      {:error, changeset}
    else
      changeset
      |> Config.repo.update
    end
  end

  @doc """
  Unlock a user account.

  Clears the `:locked_at` field on the user model and updates the database.
  """
  @spec unlock!(Ecto.Schema.t) :: schema_or_error
  def unlock!(user) do
    user_schema = Config.user_schema
    changeset = user_schema.unlock user
    if user_schema.locked?(user) do
      changeset
      |> Config.repo.update
    else
      changeset = Ecto.Changeset.add_error changeset, :locked_at, Messages.backend().not_locked()
      {:error, changeset}
    end
  end


  @doc """
  Plug to redirect already logged in users.
  """
  @spec redirect_logged_in(conn, params) :: conn
  def redirect_logged_in(conn, _params) do
    if Coherence.logged_in?(conn) do
      conn
      |> put_flash(:info, Messages.backend().already_logged_in())
      |> redirect(to: logged_in_url(conn))
      |> halt
    else
      conn
    end
  end

  @spec redirect_to(conn, atom, params) :: conn
  def redirect_to(conn, path, params) do
    apply(Coherence.Redirects, path, [conn, params])
  end

  @spec redirect_to(conn, atom, params, schema) :: conn
  def redirect_to(conn, path, params, user) do
    apply(Coherence.Redirects, path, [conn, params, user])
  end

  @spec changeset(atom, module, schema, params) :: changeset
  def changeset(which, module, model, params \\ %{})
  def changeset(:password, module, model, params) do
    fun = Application.get_env :coherence, :changeset, :changeset
    apply module, fun, [model, params, :password]
  end
  def changeset(which, module, model, params) do
    {mod, fun, args} = case Application.get_env :coherence, :changeset do
      nil -> {module, :changeset, [model, params]}
      {mod, fun} -> {mod, fun, [model, params, which]}
    end
    apply mod, fun, args
  end

  @doc """
  Login a user.

  Logs in a user and redirects them to the session_create page.
  """
  @spec login_user(conn, schema, params) :: conn
  def login_user(conn, user, _params \\ %{}) do
     Config.auth_module
     |> apply(Config.create_login, [conn, user, [id_key: Config.schema_key]])
     |> TrackableService.track_login(user, Config.user_schema.trackable?, Config.user_schema.trackable_table?)
  end

  @doc """
  Logout a user.

  Logs out a user and redirects them to the session_delete page.
  """
  @spec logout_user(conn) :: conn
  def logout_user(conn) do
    user = Coherence.current_user conn
    Config.auth_module
    |> apply(Config.delete_login, [conn, [id_key: Config.schema_key]])
    |> TrackableService.track_logout(user, user.__struct__.trackable?, user.__struct__.trackable_table?)
    |> RememberableService.delete_rememberable(user)
  end

end
