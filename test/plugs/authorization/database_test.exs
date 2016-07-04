defmodule CoherenceTest.Plug.Database do
  use ExUnit.Case, async: true
  use Plug.Test
  alias Coherence.Authentication.Database

  @default_opts [
    store: :cookie,
    key: "_test",
    encryption_salt: "abcdefgh",
    signing_salt: "abcdefgh",
    log: false
  ]

  @session_opts Plug.Session.init @default_opts

  @secret String.duplicate("abcdef0123456789", 8)
  @signing_opts Plug.Session.init(Keyword.put(@default_opts, :encrypt, false))
  @encrypted_opts Plug.Session.init(@default_opts)

  def sign_conn(conn, secret \\ @secret) do
    put_in(conn.secret_key_base, secret)
    |> Plug.Session.call(@signing_opts)
    |> fetch_session
  end

  # defp encrypt_conn(conn) do
  #   put_in(conn.secret_key_base, @secret)
  #   |> Plug.Session.call(@encrypted_opts)
  #   |> fetch_session
  # end

  defmodule TestPlug do
    use Plug.Builder
    import Plug.Conn

    plug :fetch_session
    plug Coherence.Authentication.Database, db_model: TestCoherence.User #, login: &Coherence.SessionController.login_callback/1
    plug :index

    defp index(conn, _opts), do: send_resp(conn, 200, "Authorized")
  end

  defp call(plug, headers) do
    conn(:get, "/", headers: headers)
    |> sign_conn
    |> plug.call([])
  end

  setup do
    # Coherence.Authentication.Database.add_credentials("Admin", "SecretPass", %{role: :admin})
    :ok
  end

  test "request without credentials" do
    conn = call(TestPlug, [])
    assert conn.halted
  end

  # test "create_login" do
  #   user = %{id: 1, email: "test@example.com"}
  #   conn = call(TestPlug, [])
  #   # |> sign_conn
  #   |> Database.create_login(user)

  #   assert conn.assigns[:authenticated_user] ==  user
  # end
end
