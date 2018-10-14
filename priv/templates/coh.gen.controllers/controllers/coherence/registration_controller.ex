defmodule <%= web_base %>.Coherence.RegistrationController do
  @moduledoc """
  Handle account registration actions.

  Actions:

  * new - render the register form
  * create - create a new user account
  * edit - edit the user account
  * update - update the user account
  * delete - delete the user account
  """
  use CoherenceWeb, :controller
  use Coherence.RegistrationControllerBase, schemas: <%= base %>.Coherence.Schemas

  plug(Coherence.RequireLogin when action in ~w(show edit update delete)a)
  plug(Coherence.ValidateOption, :registerable)
  plug(:scrub_params, "registration" when action in [:create, :update])

  plug(:layout_view, view: Coherence.RegistrationView, caller: __MODULE__)
  plug(:redirect_logged_in when action in [:new, :create])
end
