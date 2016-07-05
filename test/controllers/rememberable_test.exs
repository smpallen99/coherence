defmodule CoherenceTest.Rememberable do
  use TestCoherence.ConnCase
  alias Coherence.{Rememberable, SessionController}
  alias TestCoherence.{User}
  import TestCoherence.Router.Helpers

  def with_session(conn) do
    session_opts = Plug.Session.init(store: :cookie, key: "_app",
                                     encryption_salt: "abc", signing_salt: "abc")
    conn
    |> Map.put(:secret_key_base, String.duplicate("abcdefgh", 8))
    |> Plug.Session.call(session_opts)
    |> Plug.Conn.fetch_session()
    |> Plug.Conn.fetch_query_params()
    # |> Plug.Conn.fetch_params()
    |> accepts(["html"])
  end

  defp accepts(conn, opts) do
    Phoenix.Controller.accepts(conn, opts)
  end

  setup_all do
    {:ok, _pid } = TestCoherence.Endpoint.start_link
      # on_exit fn ->
      #    Supervisor.stop(pid)
      # end
    :ok
  end

  def login_cookie(%{conn: conn}) do
    user = insert_user
    {r1, series, token} = rememberable = insert_rememberable(user)
    conn = conn
    |> with_session
    |> SessionController.save_login_cookie(user.id, series, token)
    {:ok, conn: conn, user: user, rememberable: rememberable}
  end

  describe "public" do
    test "get public page", %{conn: conn} do
      conn = get conn, "/dummies"
      assert html_response(conn, 200) =~ "Index rendered"
    end

    test "private page protected", %{conn: conn} do
      conn = get conn, "/dummies/new"
      assert html_response(conn, 200) =~ "Login callback rendered"
      assert conn.halted
      assert conn.private[:plug_session]["user_return_to"] == "/dummies/new"
    end
  end

  # @tag :login_cookie
  describe "login cookie" do
    setup [:login_cookie]

    test "authenticates with correct login cookie", %{conn: conn} = meta do
      conn = get conn, "/dummies/new" # dummy_path(conn, :new)
      assert html_response(conn, 200) =~ "New rendered"
      assert conn.assigns[:remembered]
      assert conn.assigns[:authenticated_user].id == meta[:user].id
    end
    # test "logout deletes the login cookie", %{conn: conn} = meta  do
    #   conn = conn
    #   |> Coherence.Authentication.Database.create_login(meta[:user])
    #   |> delete("/sessions/#{meta[:user].id}")
    #   refute conn.cookies["coherence_login"]
    #   # refute Plug.Conn.fetch_session conn
    # end

    test "expired", %{conn: conn} = meta do

    end
  end

  describe "no login cookie" do

  end


end
