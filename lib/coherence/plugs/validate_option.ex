defmodule Coherence.ValidateOption do
  @behaviour Plug
  import Coherence.ControllerHelpers, only: [logged_out_url: 1]
  import Plug.Conn

  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  def init(options) do
    %{option: options}
  end

  def call(conn, opts) do
    if Coherence.Config.has_option(opts[:option]) do
      conn
    else
      conn
      |> put_flash(:error, "Invalid Request.")
      |> redirect(to: logged_out_url(conn))
      |> halt
    end
  end

end
