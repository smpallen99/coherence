defmodule <%= web_base %>.Coherence.UnlockController do
  @moduledoc """
  Handle unlock_with_token actions.

  This controller provides the ability generate an unlock token, send
  the user an email and unlocking the account with a valid token.

  Basic locking and unlocking does not use this controller.
  """
  use CoherenceWeb, :controller
  use Coherence.UnlockControllerBase, schemas: <%= base %>.Coherence.Schemas

  plug(Coherence.ValidateOption, :unlockable_with_token)
  plug(:layout_view, view: Coherence.UnlockView, caller: __MODULE__)
  plug(:redirect_logged_in when action in [:new, :create, :edit])
end
