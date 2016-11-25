defmodule Coherence.ControllerHelpers do
  @moduledoc """
  Common helper functions for Coherence Controllers.
  """
  alias Coherence.Config
  require Logger
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
  import Plug.Conn, only: [halt: 1]
  alias Coherence.Schema.{Confirmable}
  @lockable_failure "Failed to update lockable attributes "

  @doc """
  Get the MyProject.Router.Helpers module.

  Returns the projects Router.Helpers module.
  """
  def router_helpers do
    Module.concat(Config.module, Router.Helpers)
  end

  @doc """
  Get the configured logged_out_url.
  """
  def logged_out_url(conn) do
    Config.logged_out_url || Module.concat(Config.module, Router.Helpers).session_path(conn, :new)
  end

  @doc """
  Get the configured logged_in_url.
  """
  def logged_in_url(_conn) do
    Config.logged_in_url || "/"
  end

  @doc """
  Get a random string of given length.

  Returns a random url safe encoded64 string of the given length.
  Used to generate tokens for the various modules that require unique tokens.
  """
  def random_string(length) do
    :crypto.strong_rand_bytes(length)
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
  """
  def expired?(nil, _), do: true
  def expired?(datetime, opts) do
    expire_on? = datetime
    |> Ecto.DateTime.to_erl
    |> Timex.DateTime.from_erl
    |> Timex.shift(opts)
    not Timex.before?(Timex.DateTime.now, expire_on?)
  end

  @doc """
  Log an error message when lockable update fails.
  """
  def lockable_failure(changeset) do
    Logger.error @lockable_failure <> inspect(changeset.errors)
  end

  @doc """
  Send a user email.

  Sends a user email given the module, model, and url. Logs the email for
  debug purposes.

  Note: This function uses an apply to avoid compile warnings if the
  mailer is not selected as an option.
  """
  def send_user_email(fun, model, url) do
    email = apply(Module.concat(Config.module, Coherence.UserEmail), fun, [model, url])
    Logger.debug fn -> "#{fun} email: #{inspect email}" end
    apply(Module.concat(Config.module, Coherence.Mailer), :deliver, [email])
  end

  @doc """
  Send confirmation email with token.

  If the user supports confirmable, generate a token and send the email.
  """
  def send_confirmation(conn, user, user_schema) do
    if user_schema.confirmable? do
      token = random_string 48
      url = router_helpers.confirmation_url(conn, :edit, token)
      Logger.debug "confirmation email url: #{inspect url}"
      dt = Ecto.DateTime.utc
      user_schema.changeset(user,
        %{confirmation_token: token, confirmation_sent_at: dt})
      |> Config.repo.update!

      send_user_email :confirmation, user, url
      conn
      |> put_flash(:info, "Confirmation email sent.")
    else
      conn
      |> put_flash(:info, "Registration created successfully.")
    end
  end

  #############
  # User Schema

  @doc """
  Confirm a user account.

  Adds the `:confirmed_at` datetime field on the user model and updates the database
  """
  def confirm!(user) do
    changeset = Confirmable.confirm(user)
    unless Confirmable.confirmed? user do
      Config.repo.update changeset
    else
      changeset = Ecto.Changeset.add_error changeset, :confirmed_at, "already confirmed"
      {:error, changeset}
    end
  end

  @doc """
  Lock a use account.

  Sets the `:locked_at` field on the user model to the current date and time unless
  provided a value for the optional parameter.

  You can provide a date in the future to override the configured lock expiry time. You
  can set this data far in the future to do a pseudo permanent lock.
  """

  def lock!(user, locked_at \\ Ecto.DateTime.utc) do
    user_schema = Config.user_schema
    changeset = user_schema.lock user, locked_at
    unless user_schema.locked?(user) do
      changeset
      |> Config.repo.update
    else
      changeset = Ecto.Changeset.add_error changeset, :locked_at, "already locked"
      {:error, changeset}
    end
  end

  @doc """
  Unlock a user account.

  Clears the `:locked_at` field on the user model and updates the database.
  """
  def unlock!(user) do
    user_schema = Config.user_schema
    changeset = user_schema.unlock user
    if user_schema.locked?(user) do
      changeset
      |> Config.repo.update
    else
      changeset = Ecto.Changeset.add_error changeset, :locked_at, "not locked"
      {:error, changeset}
    end
  end


  @doc """
  Plug to redirect already logged in users.
  """
  def redirect_logged_in(conn, _params) do
    if Coherence.logged_in?(conn) do
      conn
      |> put_flash(:info, "Already logged in." )
      |> redirect(to: logged_in_url(conn))
      |> halt
    else
      conn
    end
  end

  def redirect_to(conn, path, params) do
    apply(Coherence.Redirects, path, [conn, params])
  end
  def redirect_to(conn, path, params, user) do
    apply(Coherence.Redirects, path, [conn, params, user])
  end

  def changeset(which, module, model, params \\ %{}) do
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
  def login_user(conn, user, params) do
     apply(Config.auth_module, Config.create_login, [conn, user, [id_key: Config.schema_key]])
     |> track_login(user, Config.user_schema.trackable?)
     |> redirect_to(:session_create, params)
  end

  @doc """
  Track user login details.

  Saves the ip address and timestamp when the user logs in.
  """
  def track_login(conn, _, false), do: conn
  def track_login(conn, user, true) do
    ip = conn.peer |> elem(0) |> inspect
    now = Ecto.DateTime.utc
    {last_at, last_ip} = cond do
      is_nil(user.last_sign_in_at) and is_nil(user.current_sign_in_at) ->
        {now, ip}
      !!user.current_sign_in_at ->
        {user.current_sign_in_at, user.current_sign_in_ip}
      true ->
        {user.last_sign_in_at, user.last_sign_in_ip}
    end

    changeset(:session, user.__struct__, user,
      %{
        sign_in_count: user.sign_in_count + 1,
        current_sign_in_at: Ecto.DateTime.utc,
        current_sign_in_ip: ip,
        last_sign_in_at: last_at,
        last_sign_in_ip: last_ip
      })
    |> Config.repo.update
    |> case do
      {:ok, _} -> nil
      {:error, _changeset} ->
        Logger.error ("Failed to update tracking!")
    end
    conn
  end


end
