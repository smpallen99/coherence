defmodule Coherence.Authentication.Basic do
  @moduledoc """
    Implements basic HTTP authentication. To use add:

      plug Coherence.Authentication.Basic, realm: "Secret world"

    to your pipeline.

    This module is derived from https://github.com/bitgamma/plug_auth which is derived from https://github.com/lexmag/blaguth
  """
  @dialyzer [
    {:nowarn_function, call: 2},
    {:nowarn_function, get_auth_header: 1},
    {:nowarn_function, verify_creds: 2},
    {:nowarn_function, assert_creds: 4},
    {:nowarn_function, init: 1},
    {:nowarn_function, halt_with_login: 3},
  ]

  @type t :: Ecto.Schema.t | Map.t
  @type conn :: Plug.Conn.t

  @behaviour Plug
  import Plug.Conn
  import Coherence.Authentication.Utils

  alias Coherence.Messages
  alias Coherence.CredentialStore.Types, as: T

  @doc """
    Returns the encoded form for the given `user` and `password` combination.
  """
  @spec encode_credentials(atom | String.t, String.t | nil) :: T.credentials
  def encode_credentials(user, password), do: Base.encode64("#{user}:#{password}")

  @spec create_login(String.t, String.t, t, Keyword.t) :: t
  def create_login(email, password, user_data, _opts \\ []) do
    creds = encode_credentials(email, password)
    store = get_credential_store()
    store.put_credentials(creds, user_data)
  end

  @doc """
    Update login store for a user. `user_data` can be any term but must not be `nil`.
  """
  @spec update_login(String.t, String.t, t, Keyword.t) :: t
  def update_login(email, password, user_data, opts  \\ []) do
    create_login(email, password, user_data, opts)
  end

  # @spec init(Keyword.t) :: map
  def init(opts) do
    %{
      realm: Keyword.get(opts, :realm, Messages.backend().restricted_area()),
      error: Keyword.get(opts, :error, Messages.backend().http_authentication_required()),
      store: Keyword.get(opts, :store, Coherence.CredentialStore.Server),
      assigns_key: Keyword.get(opts, :assigns_key, :current_user),
    }
  end

  # @spec call(conn, Keyword.t) :: none
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
