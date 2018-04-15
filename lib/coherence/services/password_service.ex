defmodule Coherence.PasswordService do
  @moduledoc """
  This service handles reseting of passwords.

  Installed with the `--recoverable` installation option, this service handles
  the creation of the `reset_password_token`. With this installation option, the
  following fields are added to the user's schema:

  * :reset_password_token - A random string token generated and sent to the user
  * :reset_password_sent_at - the date and time the token was created

  The following configuration can be used to customize the behavior of the
  recoverable option:

  * :reset_token_expire_days (2) - the expiry time of the reset token in days.

  """
  use Coherence.Config

  alias Coherence.Controller
  alias Coherence.Schemas

  @doc """
  Create and save a reset password token.

  Creates a random password reset token and saves the token in the
  user schema along with setting the `reset_password_sent_at` to the
  current time and date.
  """
  def reset_password_token(user) do
    token = Controller.random_string 48
    dt = NaiveDateTime.utc_now()
    :password
    |> Controller.changeset(user.__struct__, user,
      %{reset_password_token: token, reset_password_sent_at: dt})
    |> Schemas.update
  end

end
