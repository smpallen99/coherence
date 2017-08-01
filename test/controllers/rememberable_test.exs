defmodule CoherenceTest.Rememberable do
  use TestCoherence.ConnCase
  alias Coherence.{SessionController}
  alias TestCoherence.Coherence.Rememberable
  import TestCoherenceWeb.Router.Helpers
  import Ecto.Query

  def with_session(conn) do
    session_opts = Plug.Session.init(store: :cookie, key: "_binaryid_key",
                                     signing_salt: "JFbk5iZ6")
    conn
    |> Map.put(:secret_key_base, "HL0pikQMxNSA58Dv4mf26O/eh1e4vaJDmX0qLgqBcnS94gbKu9Xn3x114D+mHYcX")
    |> Plug.Session.call(session_opts)
    |> Plug.Conn.fetch_session()
    |> Plug.Conn.fetch_query_params()
    |> accepts(["html"])
  end

  defp accepts(conn, opts) do
    Phoenix.Controller.accepts(conn, opts)
  end

  def login_cookie(%{conn: conn}) do
    user = insert_user()
    {_, series, token} = rememberable = insert_rememberable(user)
    conn = conn
    |> with_session
    |> SessionController.save_login_cookie(user.id, series, token)
    {:ok, conn: conn, user: user, rememberable: rememberable}
  end

  describe "public" do
    test "get public page", %{conn: conn} do
      conn = get conn, dummy_path(conn, :index)
      assert html_response(conn, 200) =~ "Index rendered"
    end

    test "private page protected", %{conn: conn} do
      conn = get conn, dummy_path(conn, :new)
      assert html_response(conn, 200) =~ "Login callback rendered"
      assert conn.halted
      assert conn.private[:plug_session]["user_return_to"] == "/dummies/new"
    end
  end

  describe "login cookie" do
    setup [:login_cookie]

    test "authenticates with correct login cookie", %{conn: conn} = meta do
      conn = get conn, dummy_path(conn, :new)
      assert html_response(conn, 200) =~ "New rendered"
      assert conn.assigns[:remembered]
      assert conn.assigns[:current_user].id == meta[:user].id
    end

    test "expired", %{conn: conn} = meta do
      {rememberable, _, _} = meta[:rememberable]
      datetime = Timex.shift rememberable.token_created_at, months: -1
      Rememberable.changeset(rememberable, %{token_created_at: datetime})
      |> TestCoherence.Repo.update!
      conn = get conn, dummy_path(conn, :new)

      assert Repo.one(from r in Rememberable, select: count(r.id)) == 0
      assert html_response(conn, 200) =~ "Login callback rendered"
    end
  end

end
