defmodule Coherence.ControllerHelpers do
  alias Coherence.Config

  def router_helpers do
    Module.concat(Config.module, Router.Helpers)
  end

  def logged_out_url(conn) do
    Config.logged_out_url || Module.concat(Config.module, Router.Helpers).session_path(conn, :new)
  end
end
