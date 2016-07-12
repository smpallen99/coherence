defmodule CoherenceTest.InvitationController do
  use TestCoherence.ConnCase
  alias Coherence.{InvitationController, Config}
  alias TestCoherence.{User, Repo, Config}
  import TestCoherence.Router.Helpers

  setup_all do
    {:ok, _pid } = TestCoherence.Endpoint.start_link
    :ok
  end

  setup %{conn: conn} do
    user = insert_user
    conn = assign conn, :current_user, user
    {:ok, conn: conn, user: user}
  end

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


  test "can't invite an existing user", %{conn: conn, user: user} do
    params = %{"invitation" => %{"name" => user.name, "email" => user.email}}
    conn = post conn, invitation_path(conn, :create), params
    assert html_response(conn, 200)
  end

  test "create an account for an existing user" do

  end

  test "edit invite for custom login_field" do

  end

end
