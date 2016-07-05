defmodule TestCoherence.DummyController do
  use Phoenix.Controller

  def index(conn, _) do
    # IO.puts "################# index"
    html(conn, "Index rendered")
  end
  def new(conn, _) do
    # IO.puts "################# new"
    html conn, "New rendered"
  end
  def edit(conn, _) do
    html conn, "Edit rendered"
  end
end
