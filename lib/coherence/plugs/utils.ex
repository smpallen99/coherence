defmodule Coherence.Authentication.Utils do
  import Plug.Conn

  @param_key Application.get_env :coherence, :token_param_key, "param_key"

  def param_key, do: @param_key

  def assign_user_data(conn, user_data), do: assign(conn, :authenticated_user, user_data)
  def get_authenticated_user(conn), do: conn.assigns[:authenticated_user]
  def halt_with_error(conn, msg \\ "unauthorized") do
    conn
    |> send_resp(401, msg)
    |> halt
  end

  def get_first_req_header(conn, header), do: get_req_header(conn, header) |> header_hd

  def delete_token_session(conn) do
    case get_session(conn, param_key) do
      nil -> conn
      param -> put_session(conn, param, nil)
    end
  end

  defp header_hd([]), do: nil
  defp header_hd([head | _]), do: head

end
