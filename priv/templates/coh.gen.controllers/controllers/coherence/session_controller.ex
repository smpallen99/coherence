defmodule <%= web_base %>.Coherence.SessionController do
  @moduledoc """
  Handle the authentication actions.

  Module used for the session controller when the parent project does not
  generate controllers. Most of the work is done by the
  `Coherence.SessionControllerBase` inclusion.
  """
  use CoherenceWeb, :controller
  use Coherence.SessionControllerBase, schemas: <%= base %>.Coherence.Schemas

  plug(:layout_view, view: Coherence.SessionView, caller: __MODULE__)
  plug(:redirect_logged_in when action in [:new, :create])
end
