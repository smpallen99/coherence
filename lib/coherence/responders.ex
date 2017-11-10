defmodule Coherence.Responders do

  @callback session_create_success(conn :: term, opts :: term) :: term
  @callback session_create_error(conn :: term, opts :: term) :: term
  @callback session_create_error_locked(conn :: term, opts :: term) :: term
  @callback session_delete_success(conn :: term, opts :: term) :: term
  @callback session_already_logged_in(conn :: term, opts :: term) :: term

  @callback registration_create_success(conn :: term, opts :: term) :: term
  @callback registration_create_error(conn :: term, opts :: term) :: term
  @callback registration_update_success(conn :: term, opts :: term) :: term
  @callback registration_update_error(conn :: term, opts :: term) :: term
  @callback registration_delete_success(conn :: term, opts :: term) :: term

  @callback unlock_create_success(conn :: term, opts :: term) :: term
  @callback unlock_create_error(conn :: term, opts :: term) :: term
  @callback unlock_create_error_not_locked(conn :: term, opts :: term) :: term
  @callback unlock_update_success(conn :: term, opts :: term) :: term
  @callback unlock_update_error(conn :: term, opts :: term) :: term
  @callback unlock_update_error_not_locked(conn :: term, opts :: term) :: term

  @callback confirmation_create_success(conn :: term, opts :: term) :: term
  @callback confirmation_create_error(conn :: term, opts :: term) :: term
  @callback confirmation_update_success(conn :: term, opts :: term) :: term
  @callback confirmation_update_error(conn :: term, opts :: term) :: term

  @callback password_create_success(conn :: term, opts :: term) :: term
  @callback password_create_error(conn :: term, opts :: term) :: term
  @callback password_update_success(conn :: term, opts :: term) :: term
  @callback password_update_error(conn :: term, opts :: term) :: term

  @callback invitation_create_success(conn :: term, opts :: term) :: term
  @callback invitation_create_error(conn :: term, opts :: term) :: term
  @callback invitation_resend_success(conn :: term, opts :: term) :: term
  @callback invitation_resend_error(conn :: term, opts :: term) :: term
  @callback invitation_create_user_success(conn :: term, opts :: term) :: term
  @callback invitation_create_user_error(conn :: term, opts :: term) :: term
end
