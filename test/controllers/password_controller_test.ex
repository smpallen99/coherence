defmodule CoherenceTest.PasswordController do
  use TestCoherence.ConnCase
  import TestCoherence.Router.Helpers

  setup %{conn: conn} do
    Application.put_env :coherence, :opts, [:confirmable, :authenticatable, :recoverable,
      :lockable, :trackable, :unlockable_with_token, :invitable, :registerable]
    user = insert_user
    {:ok, conn: conn, user: user}
  end

  describe "create" do
    test "can not reset password when user not exist", %{conn: conn} do
      params = %{"password" => %{"email" => "johndoe@exampl.com", "password" => "123123", "password_confirmation" => "123123"}}
      conn = post conn, password_path(conn, :create), params
      assert conn.private[:phoenix_flash] == %{"error" => "Could not find that email address"}
      assert conn.private[:phoenix_template] == "new.html"
    end

    test "can reset password when user exist",  %{conn: conn, user: user} do
      params = %{"password" => %{"email" => user.email, "password" => "123123", "password_confirmation" => "123123"}}
      conn = post conn, password_path(conn, :create), params
      assert conn.private[:phoenix_flash] == %{"info" => "Reset email sent. Check your email for a reset link."}
      assert html_response(conn, 302)
    end
  end
end
