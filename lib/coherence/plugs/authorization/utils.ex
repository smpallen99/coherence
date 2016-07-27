defmodule Coherence.Authentication.Utils do
  @moduledoc false
  import Plug.Conn
  alias Coherence.Config

  @param_key Application.get_env :coherence, :token_param_key, "param_key"

  def param_key, do: @param_key

  def assign_user_data(conn, user_data, key \\ :current_user) do
    assign(conn, key, user_data)
  end
  def get_authenticated_user(conn, key \\ :current_user) do
    conn.assigns[key]
  end

  def halt_with_error(conn, error \\ "unauthorized")
  def halt_with_error(conn, error) when is_function(error) do
    error.(conn)
    |> halt
  end

  def halt_with_error(conn, error) do
    conn
    |> send_resp(401, error)
    |> halt
  end

  def get_first_req_header(conn, header), do: get_req_header(conn, header) |> header_hd

  def delete_token_session(conn) do
    case get_session(conn, param_key) do
      nil -> conn
      param -> put_session(conn, param, nil)
    end
  end

  def get_credential_store do
    case Config.auth_module do
      Coherence.Authentication.Session ->
        Coherence.CredentialStore.Session
      Coherence.Authentication.Basic ->
        Coherence.CredentialStore.Agent
    end
  end

  defp header_hd([]), do: nil
  defp header_hd([head | _]), do: head

  def to_string({a,b,c,d}), do: "#{a}.#{b}.#{c}.#{d}"
  def to_string(string) when is_binary(string), do: string
end
