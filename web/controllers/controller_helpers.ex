defmodule Coherence.ControllerHelpers do
  @moduledoc """
  Common helper functions for Coherence Controllers.
  """
  alias Coherence.Config
  require Logger
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
  import Plug.Conn, only: [halt: 1]

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
    user_schema = Config.user_schema
    changeset = user_schema.confirm(user)
    unless user_schema.confirmed? user do
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
      |> redirect(to: logged_out_url(conn))
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
end
