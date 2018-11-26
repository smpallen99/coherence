defmodule <%= web_base %>.Coherence.InvitationController do
  @moduledoc """
  Handle invitation actions.

  Handle the following actions:

  * new - render the send invitation form.
  * create - generate and send the invitation token.
  * edit - render the form after user clicks the invitation email link.
  * create_user - create a new user database record
  * resend - resend an invitation token email
  """
  use CoherenceWeb, :controller
  use Coherence.InvitationControllerBase, schemas: <%= base %>.Coherence.Schemas

  plug(Coherence.ValidateOption, :invitable)
  plug(:scrub_params, "user" when action in [:create_user])
  plug(:layout_view, view: Coherence.InvitationView, caller: __MODULE__)
end
