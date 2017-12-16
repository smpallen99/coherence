defmodule CoherenceTest.TrackableService do
  use TestCoherence.ConnCase

  import Ecto.Query

  alias Coherence.TrackableService, as: Service
  alias TestCoherence.{Repo, User, Coherence.Trackable}

  @session_opts [
    store: :cookie,
    key: "_test",
    signing_salt: "abcdefgh",
    log: false
  ]

  @signing_opts Plug.Session.init(@session_opts)

  defp current_user(conn), do: conn.assigns[:current_user]

  setup %{conn: conn} do
    user = insert_user()
    conn = assign(conn, :current_user, user)
    |> Plug.Session.call(@signing_opts)
    |> fetch_session
    |> struct(peer: {{127,0,0,1}, 80})
    {:ok, conn: conn, user: user}
  end

  describe "Trackable" do
    test "first login", %{conn: conn, user: user} do
      conn = Service.track_login(conn, user, true, false)
      current_user = conn.assigns[:current_user]
      assert current_user.sign_in_count == 1
      assert current_user.current_sign_in_at
      assert current_user.current_sign_in_ip == "{127, 0, 0, 1}"
      assert naive_eq?(current_user.last_sign_in_at, current_user.current_sign_in_at)
      assert current_user.last_sign_in_ip == current_user.current_sign_in_ip
    end
    test "2nd login", %{conn: conn, user: user} do
      conn = Service.track_login(conn, user, true, false)
      :timer.sleep(1500)
      conn = Service.track_login(conn, conn.assigns[:current_user], true, false)
      current_user = conn.assigns[:current_user]
      assert current_user.sign_in_count == 2
      assert current_user.current_sign_in_at
      assert current_user.current_sign_in_ip == "{127, 0, 0, 1}"
      refute naive_eq?(current_user.last_sign_in_at, current_user.current_sign_in_at)
      assert current_user.last_sign_in_ip == current_user.current_sign_in_ip
    end
    test "different IP", %{conn: conn, user: user} do
      conn = Service.track_login(conn, user, true, false)
      current_user = conn.assigns[:current_user]
      assert current_user.current_sign_in_ip == "{127, 0, 0, 1}"
      conn = struct(conn, peer: {{10,10,10,10}, 80})
      conn = Service.track_login(conn, conn.assigns[:current_user], true, false)
      current_user = conn.assigns[:current_user]
      assert current_user.current_sign_in_ip == "{10, 10, 10, 10}"
    end
    test "track_logout", %{conn: conn, user: user} do
      conn = Service.track_login(conn, user, true, false)
      Service.track_logout(conn, current_user(conn), true, false)
      user1 = Repo.get(User, user.id)
      assert user1.sign_in_count == 1
      refute user1.current_sign_in_at
      refute user1.current_sign_in_ip
      assert current_user(conn).current_sign_in_ip == user1.last_sign_in_ip
      assert naive_eq?(current_user(conn).current_sign_in_at, user1.last_sign_in_at)
    end
  end
  describe "Trackable-Table" do
    test "first login", %{conn: conn, user: user} do
      Service.track_login(conn, user, false, true)
      [trackable] = Trackable |> Repo.all
      assert trackable.sign_in_count == 1
      assert trackable.current_sign_in_at
      assert trackable.current_sign_in_ip == "{127, 0, 0, 1}"
      assert naive_eq?(trackable.last_sign_in_at, trackable.current_sign_in_at)
      assert trackable.last_sign_in_ip == trackable.current_sign_in_ip
      assert trackable.user_id == user.id
      assert trackable.action == "login"
    end
    test "track_logout", %{conn: conn, user: user} do
      Service.track_login(conn, user, false, true)
      Service.track_logout(conn, current_user(conn), false, true)
      [t1, t2] = Trackable |> order_by(asc: :id) |> Repo.all
      assert t1.action == "login"
      assert t1.sign_in_count == 1
      refute t1.current_sign_in_at
      refute t1.current_sign_in_ip

      assert t2.action == "logout"
      assert t2.sign_in_count == 1
      refute t2.current_sign_in_at
      refute t2.current_sign_in_ip

      assert t1.last_sign_in_ip == t2.last_sign_in_ip
      assert naive_eq?(t1.last_sign_in_at, t2.last_sign_in_at)
    end
    test "second login", %{conn: conn, user: user} do
      Service.track_login(conn, user, false, true)
      Service.track_logout(conn, user, false, true)
      Service.track_login(conn, user, false, true)
      [t1, t2, t3] = Trackable |> order_by(asc: :id) |> Repo.all
      assert t1.sign_in_count == 1
      assert t3.sign_in_count == 2

      assert t2.action == "logout"

      assert t3.action == "login"
      assert t3.current_sign_in_at
      assert t3.current_sign_in_ip == "{127, 0, 0, 1}"
      assert t3.user_id == user.id
      assert naive_eq?(t2.last_sign_in_at, t3.last_sign_in_at)
      assert t3.last_sign_in_ip == t2.last_sign_in_ip
    end
    test "different IP", %{conn: conn, user: user} do
      conn = Service.track_login(conn, user, false, true)
      [t1] = Trackable |> order_by(asc: :id) |> Repo.all
      assert t1.current_sign_in_ip == "{127, 0, 0, 1}"
      conn = struct(conn, peer: {{10,10,10,10}, 80})
      Service.track_login(conn, user, false, true)
      [_t1, t2] = Trackable |> order_by(asc: :id) |> Repo.all
      assert t2.current_sign_in_ip == "{10, 10, 10, 10}"
    end
    test "password reset", %{conn: conn, user: user} do
      conn = Service.track_login(conn, user, false, true)
      Service.track_logout(conn, user, false, true)
      Service.track_password_reset(conn, user, true)
      [_t1, _t2, t3] = Trackable |> order_by(asc: :id) |> Repo.all
      assert t3.action == "password_reset"
    end
    test "password_reset no login", %{conn: conn, user: user} do
      Service.track_password_reset(conn, user, true)
      [t1] = Trackable |> order_by(asc: :id) |> Repo.all
      assert t1.action == "password_reset"
      refute t1.current_sign_in_ip
      refute t1.current_sign_in_at
      refute t1.last_sign_in_at
      refute t1.last_sign_in_ip
      assert t1.sign_in_count == 0
    end
    test "failed login", %{conn: conn, user: user} do
      conn = Service.track_login(conn, user, false, true)
      Service.track_logout(conn, user, false, true)
      Service.track_failed_login(conn, user, true)
      [_t1, t2, t3] = Trackable |> order_by(asc: :id) |> Repo.all
      assert t3.action == "failed_login"
      assert naive_eq?(t2.last_sign_in_at, t3.last_sign_in_at)
      assert t2.last_sign_in_ip == t3.last_sign_in_ip
    end
    test "lock", %{conn: conn, user: user} do
      conn = Service.track_login(conn, user, false, true)
      Service.track_logout(conn, user, false, true)
      Service.track_lock(conn, user, true)
      [_t1, t2, t3] = Trackable |> order_by(asc: :id) |> Repo.all
      assert t3.action == "lock"
      assert naive_eq?(t2.last_sign_in_at, t3.last_sign_in_at)
      assert t2.last_sign_in_ip == t3.last_sign_in_ip
    end
    test "unlock", %{conn: conn, user: user} do
      conn = Service.track_login(conn, user, false, true)
      Service.track_logout(conn, user, false, true)
      Service.track_unlock(conn, user, true)
      [_t1, t2, t3] = Trackable |> order_by(asc: :id) |> Repo.all
      assert t3.action == "unlock"
      assert naive_eq?(t2.last_sign_in_at, t3.last_sign_in_at)
      assert t2.last_sign_in_ip == t3.last_sign_in_ip
    end
    test "unlock_token", %{conn: conn, user: user} do
      conn = Service.track_login(conn, user, false, true)
      Service.track_logout(conn, user, false, true)
      Service.track_unlock_token(conn, user, true)
      [_t1, t2, t3] = Trackable |> order_by(asc: :id) |> Repo.all
      assert t3.action == "unlock_token"
      assert naive_eq?(t2.last_sign_in_at, t3.last_sign_in_at)
      assert t2.last_sign_in_ip == t3.last_sign_in_ip
    end

  end

  defp naive_eq?(%NaiveDateTime{} = dt1, %NaiveDateTime{} = dt2) do
    remove_microsecond(dt1) == remove_microsecond(dt2)
  end

  defp remove_microsecond(%NaiveDateTime{} = dt), do: struct(dt, microsecond: {0, 0})
end
