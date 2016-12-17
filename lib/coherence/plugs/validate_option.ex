defmodule Coherence.ValidateOption do
  @behaviour Plug
  import Coherence.ControllerHelpers, only: [logged_out_url: 1]
  import Plug.Conn

  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  @dialyzer [
    {:nowarn_function, call: 2},
    {:nowarn_function, init: 1},
  ]

  @spec init(Keyword.t | atom) :: [tuple]
  def init(options) do
    %{option: options}
  end

  @spec call(Plug.Conn.t, Map.t) :: Plug.Conn.t
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
