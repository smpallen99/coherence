defmodule Coherence.ControllerHelpers do
  @moduledoc """
  Common helper functions for Coherence Controllers.
  """
  alias Coherence.Config
  require Logger

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
end
