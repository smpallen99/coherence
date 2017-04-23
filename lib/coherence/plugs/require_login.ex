defmodule Coherence.RequireLogin do
  @moduledoc """
  Plug to protect controllers that require login.
  """

  import Coherence.ControllerHelpers, only: [logged_out_url: 1]
  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
  import Coherence.Gettext

  @behaviour Plug

  @dialyzer [
    {:nowarn_function, call: 2},
    {:nowarn_function, init: 1},
  ]

  @spec init(Keyword.t) :: [tuple]
  def init(options) do
    %{option: options}
  end

  @spec call(Plug.Conn.t, any) :: Plug.Conn.t
  def call(conn, _opts) do
    if Coherence.current_user(conn) do
      conn
    else
      conn
      |> put_flash(:error, dgettext("coherence", "Invalid Request."))
      |> redirect(to: logged_out_url(conn))
      |> halt
    end
  end

end
