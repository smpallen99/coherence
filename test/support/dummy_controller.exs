defmodule TestCoherenceWeb.DummyController do
  use Phoenix.Controller

  def index(conn, _) do
    html(conn, "Index rendered")
  end
  def new(conn, _) do
    html conn, "New rendered"
  end
  def edit(conn, _) do
    html conn, "Edit rendered"
  end
end
