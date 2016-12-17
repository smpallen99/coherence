defmodule CoherenceTest.TrackableService do
  use TestCoherence.ConnCase
  alias Coherence.TrackableService, as: Service
  alias TestCoherence.{Repo, User}

  defp current_user(conn), do: conn.assigns[:current_user]

  setup %{conn: conn} do
    user = insert_user
    conn = assign(conn, :current_user, user)
    |> struct(peer: {{127,0,0,1}, 80})
    {:ok, conn: conn, user: user}
  end

  describe "Trackable" do
    test "first login", %{conn: conn, user: user} do
      conn = Service.track_login(conn, user, true)
      current_user = conn.assigns[:current_user]
      assert current_user.sign_in_count == 1
      assert current_user.current_sign_in_at
      assert current_user.current_sign_in_ip == "{127, 0, 0, 1}"
      assert current_user.last_sign_in_at == current_user.current_sign_in_at
      assert current_user.last_sign_in_ip == current_user.current_sign_in_ip
    end
    test "2nd login", %{conn: conn, user: user} do
      conn = Service.track_login(conn, user, true)
      :timer.sleep(1500)
      conn = Service.track_login(conn, conn.assigns[:current_user], true)
      current_user = conn.assigns[:current_user]
      assert current_user.sign_in_count == 2
      assert current_user.current_sign_in_at
      assert current_user.current_sign_in_ip == "{127, 0, 0, 1}"
      refute current_user.last_sign_in_at == current_user.current_sign_in_at
      assert current_user.last_sign_in_ip == current_user.current_sign_in_ip
    end
    test "different IP", %{conn: conn, user: user} do
      conn = Service.track_login(conn, user, true)
      current_user = conn.assigns[:current_user]
      assert current_user.current_sign_in_ip == "{127, 0, 0, 1}"
      conn = struct(conn, peer: {{10,10,10,10}, 80})
      conn = Service.track_login(conn, conn.assigns[:current_user], true)
      current_user = conn.assigns[:current_user]
      assert current_user.current_sign_in_ip == "{10, 10, 10, 10}"
    end
    test "track_logout", %{conn: conn, user: user} do
      conn = Service.track_login(conn, user, true)
      Service.track_logout(conn, current_user(conn), true)
      user1 = Repo.get(User, user.id)
      assert user1.sign_in_count == 1
      refute user1.current_sign_in_at
      refute user1.current_sign_in_ip
      assert current_user(conn).current_sign_in_ip == user1.last_sign_in_ip
      assert current_user(conn).current_sign_in_at == user1.last_sign_in_at
    end
  end
end
