defmodule CoherenceTest.Plug.Session do
  use ExUnit.Case, async: true
  use Plug.Test
  alias Coherence.Authentication.Session
  alias Coherence.{Config}
  alias TestCoherence.{User, Coherence.Rememberable}
  require Ecto.Query

  @default_opts [
    store: :cookie,
    key: "_test",
    encryption_salt: "abcdefgh",
    signing_salt: "abcdefgh",
    log: false
  ]

  @secret String.duplicate("abcdef0123456789", 8)
  @signing_opts Plug.Session.init(Keyword.put(@default_opts, :encrypt, false))

  def sign_conn(conn, secret \\ @secret) do
    put_in(conn.secret_key_base, secret)
    |> Plug.Session.call(@signing_opts)
    |> fetch_session
  end

  defmodule TestPlug do
    use Plug.Builder
    import Plug.Conn

    plug :accepts, ["html"]
    plug :fetch_session
    plug Coherence.Authentication.Session, login: true
    plug :index

    defp index(conn, _opts), do: send_resp(conn, 200, "Authorized")
    defp accepts(conn, params), do: Phoenix.Controller.accepts(conn, params)
  end

  defmodule RememberablePlug do
    use Plug.Builder
    import Plug.Conn

    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Coherence.Authentication.Session, login: true, rememberable: true, rememberable_callback: &Coherence.SessionController.do_rememberable_callback/5
    plug :index

    defp index(conn, _opts), do: send_resp(conn, 200, "Authorized")
    defp fetch_flash(conn, params), do: Phoenix.Controller.fetch_flash(conn, params)
    defp accepts(conn, params), do: Phoenix.Controller.accepts(conn, params)
  end


  defp call(plug, headers) do
    conn(:get, "/", headers: headers)
    |> Phoenix.Controller.put_view(TestCoherence.Coherence.SessionView)
    |> sign_conn
    |> plug.call([])
  end

  setup do
    user = %{id: 1, role: :admin}
    # Coherence.Authentication.Session.add_credentials("Admin", "SecretPass", user)
    {:ok, user: user}
  end

  @user_params %{name: "test", email: "test@test.com", password: "secret", password_confirmation: "secret"}

  test "request without credentials" do
    conn = call(TestPlug, [])
    assert conn.halted
  end

  defp call_cookie(plug, headers, cookie) do
    conn(:get, "/", headers: headers)
    |> sign_conn
    |> put_resp_cookie("coherence_login", cookie)
    |> Phoenix.Controller.put_view(TestCoherence.Coherence.SessionView)
    |> plug.call([])
  end
  def save_login_cookie(conn, id, series, token, key, expire) do
    put_resp_cookie conn, key, "#{id} #{series} #{token}", max_age: expire
  end

  describe "login cookie" do
    setup [:valid_login_cookie]
    test "validates login_cookie", meta do
      conn = call_cookie(RememberablePlug, [], meta[:cookie])
      assert conn.status == 200
      assert conn.resp_body == "Authorized"
      assert conn.assigns[:remembered]
    end
    test "does not validate invalid series login_cookie", meta do
      [id, series, token] = meta[:cookie] |> String.split(" ")
      series = series <> "sb"
      cookie = "#{id} #{series} #{token}"

      conn = call_cookie(RememberablePlug, [], cookie)
      assert conn.status == 302
      refute conn.resp_body == "Authorized"
      refute conn.assigns[:remembered]
    end
    test "does not validate invalid token login_cookie", meta do
      [id, series, token] = meta[:cookie] |> String.split(" ")
      token = token <> "abc"
      cookie = "#{id} #{series} #{token}"

      conn = call_cookie(RememberablePlug, [], cookie)
      assert get_in(conn.private, [:phoenix_flash, "error"]) =~ "You are using an invalid security token for this site!"
      assert conn.status == 302
      refute conn.assigns[:remembered]

      id = String.to_integer id
      list = Ecto.Query.where(Rememberable, [u], u.user_id == ^id)
      |> TestCoherence.Repo.all
      assert list == []
    end
    test "uses session over remember me", meta do
      conn = conn(:get, "/", headers: [])
      |> sign_conn
      |> put_resp_cookie("coherence_login", meta[:cookie])
      |> Session.create_login(meta[:user])
      |> RememberablePlug.call([])
      assert conn.status == 200
      assert conn.resp_body == "Authorized"
      refute conn.assigns[:remembered]
    end
    test "uses login token with lost session store", meta do
      conn = conn(:get, "/", headers: [])
      |> sign_conn
      |> put_resp_cookie("coherence_login", meta[:cookie])
      |> Session.create_login(meta[:user])
      |> RememberablePlug.call([])
      creds = get_session(conn, "session_auth")
      assert creds
      Coherence.CredentialStore.Session.delete_credentials creds

      conn = conn(:get, "/", headers: [])
      |> sign_conn
      |> put_resp_cookie("coherence_login", meta[:cookie])
      |> RememberablePlug.call([])
      assert conn.status == 200
      assert conn.resp_body == "Authorized"
      assert conn.assigns[:remembered]
    end
  end

  def valid_login_cookie(_) do
    Ecto.Adapters.SQL.Sandbox.checkout(TestCoherence.Repo)
    opts = Config.opts
    user_schema = Config.user_schema
    Application.put_env :coherence, :opts, [:rememberable | opts]
    Application.put_env :coherence, :user_schema, TestCoherence.User

    on_exit fn ->
      Application.put_env :coherence, :opts, opts
      Application.put_env :coherence, :user_schema, user_schema
    end

    {:ok, user} = User.changeset(%User{}, @user_params)
    |> TestCoherence.Repo.insert
    {changeset, series, token} = Rememberable.create_login(user)
    cookie = "#{user.id} #{series} #{token}"
    {:ok, r1} = TestCoherence.Repo.insert changeset
    {:ok, r1: r1, user: user, series: series, token: token, cookie: cookie}
  end

end
