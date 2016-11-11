defmodule Coherence.Authentication.Basic do
  @moduledoc """
    Implements basic HTTP authentication. To use add:

      plug Coherence.Authentication.Basic, realm: "Secret world"

    to your pipeline.

    This module is derived from https://github.com/bitgamma/plug_auth which is derived from https://github.com/lexmag/blaguth
  """

  @behaviour Plug
  import Plug.Conn
  import Coherence.Authentication.Utils

  @doc """
    Returns the encoded form for the given `user` and `password` combination.
  """
  def encode_credentials(user, password), do: Base.encode64("#{user}:#{password}")

  def create_login(email, password, user_data, _opts \\ []) do
    creds = encode_credentials(email, password)
    store = get_credential_store
    store.put_credentials(creds, user_data)
  end

  @doc """
    Update login store for a user. `user_data` can be any term but must not be `nil`.
  """
  def update_login(email, password, user_data, opts  \\ []) do
    create_login(email, password, user_data, opts)
  end


  def init(opts) do
    %{
      realm: Keyword.get(opts, :realm, "Restricted Area"),
      error: Keyword.get(opts, :error, "HTTP Authentication Required"),
      store: Keyword.get(opts, :store, Coherence.CredentialStore.Agent),
      assigns_key: Keyword.get(opts, :assigns_key, :current_user),
    }
  end

  def call(conn, opts) do
    conn
    |> get_auth_header
    |> verify_creds(opts[:store])
    |> assert_creds(opts[:realm], opts[:error], opts[:assigns_key])
  end

  defp get_auth_header(conn), do: {conn, get_first_req_header(conn, "authorization")}

  defp verify_creds({conn, << "Basic ", creds::binary >>}, store), do: {conn, store.get_user_data(creds)}
  defp verify_creds({conn, _}, _), do: {conn, nil}

  defp assert_creds({conn, nil}, realm, error, _), do: halt_with_login(conn, realm, error)
  defp assert_creds({conn, user_data}, _, _, key), do: assign_user_data(conn, user_data, key)

  defp halt_with_login(conn, realm, error) do
    conn
    |> put_resp_header("www-authenticate", ~s{Basic realm="#{realm}"})
    |> halt_with_error(error)
  end
end
