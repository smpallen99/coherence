defmodule <%= web_base %>.Coherence.PasswordController do
  @moduledoc """
  Handle password recovery actions.

  Controller that handles the recover password feature.

  Actions:

  * new - render the recover password form
  * create - verify user's email address, generate a token, and send the email
  * edit - render the reset password form
  * update - verify password, password confirmation, and update the database
  """
  use CoherenceWeb, :controller
  use Coherence.PasswordControllerBase, schemas: <%= base %>.Coherence.Schemas

  plug(:layout_view, view: Coherence.PasswordView, caller: __MODULE__)
  plug(:redirect_logged_in when action in [:new, :create, :edit, :update])
end
