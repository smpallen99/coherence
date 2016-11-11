defmodule CoherenceTest.PasswordController do
  use TestCoherence.ConnCase
  import TestCoherence.Router.Helpers
  import Coherence.ControllerHelpers, only: [random_string: 1]

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

  describe "edit" do
    test "invalid reset password token", %{conn: conn, user: user} do
      params = %{"id" => "123456789"}
      conn = get conn, password_path(conn, :edit, user), params
      assert conn.private[:phoenix_flash] == %{"error" => "Invalid reset token."}
      assert html_response(conn, 302)
    end

    test "valid token has expired", %{conn: conn} do
      token = random_string 48
      {:ok, sent_at} = Ecto.DateTime.cast("2016-01-01 00:00:00")
      insert_user(%{reset_password_sent_at: sent_at, reset_password_token: token})
      params = %{"id" => token}
      conn = get conn, password_path(conn, :edit, token), params
      assert conn.private[:phoenix_flash] == %{"error" => "Password reset token expired."}
      assert html_response(conn, 302)
    end

    test "valid token hasn't expired", %{conn: conn} do
      token = random_string 48
      insert_user(%{reset_password_sent_at: Ecto.DateTime.utc, reset_password_token: token})
      params = %{"id" => token}
      conn = get conn, password_path(conn, :edit, token), params
      assert conn.private[:phoenix_template] == "edit.html"
      assert html_response(conn, 200)
    end
  end
end
