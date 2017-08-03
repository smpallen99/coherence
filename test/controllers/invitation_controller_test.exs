defmodule CoherenceTest.InvitationController do
  use TestCoherence.ConnCase
  import TestCoherenceWeb.Router.Helpers
  import Coherence.Controller, only: [random_string: 1]

  setup %{conn: conn} do
    Application.put_env :coherence, :opts, [:confirmable, :authenticatable, :recoverable,
      :lockable, :trackable, :unlockable_with_token, :invitable, :registerable]
    user = insert_user()
    conn = assign conn, :current_user, user
    {:ok, conn: conn, user: user}
  end

  describe "create" do
    test "can't invite an existing user", %{conn: conn, user: user} do
      params = %{"invitation" => %{"name" => user.name, "email" => user.email}}
      conn = post conn, invitation_path(conn, :create), params
      assert html_response(conn, 200)
      assert conn.private[:phoenix_template] == "new.html"
    end

    test "can invite new user", %{conn: conn} do
      params = %{"invitation" => %{"name" => "John Doe", "email" => "john@example.com"}}
      conn = post conn, invitation_path(conn, :create), params
      assert conn.private[:phoenix_flash] == %{"info" => "Invitation sent."}
      assert html_response(conn, 302)
    end
  end

  describe "new" do
    test "can visit registration page", %{conn: conn} do
      conn = assign conn, :current_user, nil
      conn = get conn, invitation_path(conn, :new)
      assert html_response(conn, 200)
    end
  end

  describe "create_user" do
    test "can't create new user when invitation token not exist", %{conn: conn} do
      token = random_string 48
      params = %{"user" => %{}, "token" => token }
      conn = post conn, invitation_path(conn, :create_user), params
      assert conn.private[:phoenix_flash] == %{"error" => "Invalid Invitation. Please contact the site administrator."}
      assert html_response(conn, 302)
    end

    test "can create new user when invitation token exist", %{conn: conn} do
      invitation = insert_invitation()
      params = %{"user" => %{"name" => invitation.name, "email" => invitation.email, password: "12345678"}, "token" => invitation.token }
      conn = post conn, invitation_path(conn, :create_user), params
      assert conn.private[:phoenix_flash] == %{"error" => "Mailer configuration required!"}
      assert html_response(conn, 302)
    end
  end
end
