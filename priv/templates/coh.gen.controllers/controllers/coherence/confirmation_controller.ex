defmodule <%= web_base %>.Coherence.ConfirmationController do
  @moduledoc """
  Handle confirmation actions.

  A single action, `edit`, is required for the confirmation module.

  """
  use CoherenceWeb, :controller
  use Coherence.ConfirmationControllerBase, schemas: <%= base %>.Coherence.Schemas

  plug(Coherence.ValidateOption, :confirmable)
  plug(:layout_view, view: Coherence.ConfirmationView, caller: __MODULE__)
  plug(:redirect_logged_in when action in [:new])
end
