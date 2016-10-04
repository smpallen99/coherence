defmodule CoherenceTest.InvitationController do
  use TestCoherence.ConnCase
  import TestCoherence.Router.Helpers

  setup %{conn: conn} do
    Application.put_env :coherence, :opts, [:confirmable, :authenticatable, :recoverable,
      :lockable, :trackable, :unlockable_with_token, :invitable, :registerable]
    user = insert_user
    conn = assign conn, :current_user, user
    {:ok, conn: conn, user: user}
  end

  test "can't invite an existing user", %{conn: conn, user: user} do
    params = %{"invitation" => %{"name" => user.name, "email" => user.email}}
    conn = post conn, invitation_path(conn, :create), params
    assert html_response(conn, 200)
    assert conn.private[:phoenix_template] == "new.html"
  end

end
