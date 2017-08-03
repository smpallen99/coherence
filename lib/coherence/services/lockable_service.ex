defmodule Coherence.LockableService do
  @moduledoc """
  Lockable disables an account after too many failed login attempts.

  Enabled with the `--lockable` installation option, after 5 failed login
  attempts, the user is locked out of their account for 5 minutes.

  This option adds the following fields to the user schema:

  * :failed_attempts, :integer - The number of failed login attempts.
  * :locked_at, :datetime - The time and date when the account was locked.

  The following configuration is used to customize lockable behavior:

  * :unlock_timeout_minutes (20) - The number of minutes to wait before unlocking the account.
  * :max_failed_login_attempts (5) - The number of failed login attempts before locking the account.

  By default, a locked account will be unlocked after the `:unlock_timeout_minutes` expires or the
  is unlocked using the `unlock` API.

  In addition, the `--unlock-with-token` option can be given to the installer to allow
  a user to unlock their own account by requesting an email be sent with an link containing an
  unlock token.

  With this option installed, the following field is added to the user schema:

  * :unlock_token, :string

  """
  use Coherence.Config
  alias Coherence.Controller

  def unlock_token(user) do
    token = Controller.random_string 48
    [Config.module, Coherence, Schemas]
    |> Module.concat
    |> apply(:update_user, [user, %{unlock_token: token}])
  end

end
