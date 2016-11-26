defmodule Coherence.RequireLogin do
  @behaviour Plug
  import Coherence.ControllerHelpers, only: [logged_out_url: 1]
  import Plug.Conn

  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  def init(options) do
    %{option: options}
  end

  def call(conn, _opts) do
    unless Coherence.current_user(conn) do
      conn
      |> put_flash(:error, "Invalid Request.")
      |> redirect(to: logged_out_url(conn))
      |> halt
    else
      conn
    end
  end

end
