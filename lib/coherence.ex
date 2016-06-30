defmodule Coherence do
  use Application

  @doc false
  def start(_type, _args) do
    Coherence.Supervisor.start_link()
  end

  def current_user(conn), do: conn.assigns[:authenticated_user]
  def logged_in?(conn), do: !!current_user(conn)
end
