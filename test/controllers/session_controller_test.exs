defmodule CoherenceTest.SessionController do
  use TestCoherence.ConnCase
  import TestCoherenceWeb.Router.Helpers
  alias Coherence.Controller
  alias TestCoherence.Coherence.Trackable
  import Ecto.Query
  alias TestCoherence.User

  def setup_trackable_table %{conn: conn} do
    Application.put_env :coherence, :opts, [:authenticatable, :recoverable,
      :lockable, :trackable_table, :unlockable_with_token, :invitable, :registerable]
    Application.put_env(:coherence, :max_failed_login_attempts, 2)
    user = insert_user()
    conn = assign conn, :current_user, user
    {:ok, conn: conn, user: user}
  end

  describe "trackable table" do
    setup [:setup_trackable_table]

    test "track login", %{conn: conn, user: user} do
      conn = assign conn, :current_user, nil
      params = %{"session" => %{"email" => user.email, "password" => "supersecret"}}
      conn = post conn, session_path(conn, :create), params
      assert html_response(conn, 302)
      [t1] = Trackable |> order_by(asc: :id) |> Repo.all
      assert t1.action == "login"
    end
    test "track logout", %{conn: conn, user: user} do
      conn = assign conn, :current_user, nil
      params = %{"session" => %{"email" => user.email, "password" => "supersecret"}}
      conn = post conn, session_path(conn, :create), params
      conn = delete conn, session_path(conn, :delete)
      assert html_response(conn, 302)
      [t1, t2] = Trackable |> order_by(asc: :id) |> Repo.all
      assert t1.action == "login"
      assert t2.action == "logout"
    end
    test "failed login", %{conn: conn, user: user} do
      conn = assign conn, :current_user, nil
      params = %{"session" => %{"email" => user.email, "password" => "wrong"}}
      conn = post conn, session_path(conn, :create), params
      assert html_response(conn, 401)
      [t1] = Trackable |> order_by(asc: :id) |> Repo.all
      assert t1.action == "failed_login"
    end
    test "lock", %{conn: conn, user: user} do
      conn = assign conn, :current_user, nil
      params = %{"session" => %{"email" => user.email, "password" => "wrong"}}
      conn = post conn, session_path(conn, :create), params
      conn = post conn, session_path(conn, :create), params
      assert html_response(conn, 401)
      trackables = Trackable |> order_by(asc: :id) |> Repo.all
      assert Enum.at(trackables, 0).action == "failed_login"
      assert Enum.at(trackables, 1).action == "failed_login"
      assert Enum.at(trackables, 2).action == "lock"
    end
    test "unlock", %{conn: conn, user: user} do
      conn = assign conn, :current_user, nil
      params = %{"session" => %{"email" => user.email, "password" => "wrong"}}
      conn = post conn, session_path(conn, :create), params
      conn = post conn, session_path(conn, :create), params
      assert html_response(conn, 401)
      user = Repo.get(User, user.id)
      locked_at = user.locked_at |> Controller.shift(days: -10)
      User.changeset(user, %{locked_at: locked_at})
      |> Repo.update!
      params = put_in params, ["session", "password"], "supersecret"
      post conn, session_path(conn, :create), params
      trackables = Trackable |> order_by(asc: :id) |> Repo.all
      assert Enum.count(trackables) == 5
      assert Enum.at(trackables, 2).action == "lock"
      assert Enum.at(trackables, 3).action == "unlock"
      assert Enum.at(trackables, 4).action == "login"
    end
  end
end
