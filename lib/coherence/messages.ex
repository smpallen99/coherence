defmodule Coherence.Messages do
  @moduledoc """
  Interface for handling localization of build in Coherence messages.

  The following module defines the behaviour for rendering internal
  coherence messages.

  The coherence mix tasks generate a messages file in the user's app
  that uses this behaviour to ensure the user has implement all the
  required messages.
  """

  @callback cant_be_blank() :: binary
  @callback invalid_current_password() :: binary
  @callback account_already_confirmed() :: binary
  @callback account_is_not_locked() :: binary
  @callback account_updated_successfully() :: binary
  @callback already_logged_in() :: binary
  @callback cant_find_that_token() :: binary
  @callback confirmation_token_expired() :: binary
  @callback could_not_find_that_email_address() :: binary
  @callback forgot_your_password() :: binary
  @callback http_authentication_required() :: binary
  @callback incorrect_login_or_password([{atom, any}]) :: binary
  @callback invalid_invitation() :: binary
  @callback invalid_request() :: binary
  @callback invalid_confirmation_token() :: binary
  @callback invalid_email_or_password() :: binary
  @callback invalid_invitation_token() :: binary
  @callback invalid_reset_token() :: binary
  @callback invalid_unlock_token() :: binary
  @callback invitation_already_sent() :: binary
  @callback invitation_sent() :: binary
  @callback invite_someone() :: binary
  @callback maximum_login_attempts_exceeded() :: binary
  @callback need_an_account() :: binary
  @callback password_reset_token_expired() :: binary
  @callback problem_confirming_user_account() :: binary
  @callback registration_created_successfully() :: binary
  @callback resend_confirmation_email() :: binary
  @callback reset_email_sent() :: binary
  @callback restricted_area() :: binary
  @callback send_an_unlock_email() :: binary
  @callback sign_in() :: binary
  @callback sign_out() :: binary
  @callback signed_in_successfully() :: binary
  @callback too_many_failed_login_attempts() :: binary
  @callback unauthorized_ip_address() :: binary
  @callback unlock_instructions_sent() :: binary
  @callback user_account_confirmed_successfully() :: binary
  @callback user_already_has_an_account() :: binary
  @callback you_are_using_an_invalid_security_token() :: binary
  @callback you_must_confirm_your_account() :: binary
  @callback your_account_has_been_unlocked() :: binary
  @callback your_account_is_not_locked() :: binary
  @callback already_confirmed() :: binary
  @callback not_locked() :: binary
  @callback required() :: binary
  @callback verify_user_token([{atom, any}]) :: binary
  @callback mailer_required() :: binary
  @callback account_is_inactive() :: binary

  @doc """
  Returns the Messages module from the users app's configuration
  """
  def backend do
    Coherence.Config.messages_backend()
  end
end

