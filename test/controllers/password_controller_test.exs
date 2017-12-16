defmodule CoherenceTest.PasswordController do
  use TestCoherence.ConnCase
  import TestCoherenceWeb.Router.Helpers
  import Coherence.Controller, only: [random_string: 1]
  alias TestCoherence.Repo
  alias TestCoherence.Coherence.Trackable
  alias Coherence.PasswordService

  setup %{conn: conn} do
    Application.put_env :coherence, :opts, [:confirmable, :authenticatable, :recoverable,
      :lockable, :trackable, :unlockable_with_token, :invitable, :registerable]
    user = insert_user()
    {:ok, conn: conn, user: user}
  end

  def setup_trackable_table(%{conn: conn}) do
    Application.put_env :coherence, :opts, [:confirmable, :authenticatable, :recoverable,
      :lockable, :trackable_table, :unlockable_with_token, :invitable, :registerable]
    user = insert_user()
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
      assert conn.private[:phoenix_flash] == %{"error" => "Mailer configuration required!"}
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
      sent_at = ~N(2016-01-01 00:00:00)
      insert_user(%{reset_password_sent_at: sent_at, reset_password_token: token})
      params = %{"id" => token}
      conn = get conn, password_path(conn, :edit, token), params
      assert conn.private[:phoenix_flash] == %{"error" => "Password reset token expired."}
      assert html_response(conn, 302)
    end

    test "valid token hasn't expired", %{conn: conn} do
      token = random_string 48
      insert_user(%{reset_password_sent_at: NaiveDateTime.utc_now(), reset_password_token: token})
      params = %{"id" => token}
      conn = get conn, password_path(conn, :edit, token), params
      assert conn.private[:phoenix_template] == "edit.html"
      assert html_response(conn, 200)
    end
  end

  describe "update" do
    test "valid token", %{conn: conn} do
      token = random_string 48
      user = insert_user(%{reset_password_sent_at: NaiveDateTime.utc_now(), reset_password_token: token})
      old_password_hash = user.password_hash
      params = %{"password" => %{reset_password_token: token, password: "123123", password_confirmation: "123123"}}
      put(conn, password_path(conn, :update, user.id), params)
      user = Repo.get!(TestCoherence.User, user.id)
      refute old_password_hash == user.password_hash
      assert user.reset_password_token == nil
      assert user.reset_password_sent_at == nil
    end

    test "invalid reset password token", %{conn: conn} do
      token = random_string 48
      user = insert_user(%{reset_password_sent_at: NaiveDateTime.utc_now(), reset_password_token: token})
      old_password_hash = user.password_hash
      old_sent_at = user.reset_password_sent_at
      params = %{"password" => %{reset_password_token: "1234567890", password: "123123", password_confirmation: "123123"}}
      put(conn, password_path(conn, :update, user.id), params)
      user = Repo.get!(TestCoherence.User, user.id)

      assert old_password_hash == user.password_hash
      assert user.reset_password_token == token
      assert user.reset_password_sent_at == old_sent_at
    end

    test "valid token has expired, reset token gets removed", %{conn: conn} do
      sent_at = ~N(2016-01-01 00:00:00)
      token = random_string 48
      user = insert_user(%{reset_password_sent_at: sent_at, reset_password_token: token})
      old_password_hash = user.password_hash
      params = %{"password" => %{reset_password_token: token, password: "123123", password_confirmation: "123123"}}
      put(conn, password_path(conn, :update, user.id), params)
      user = Repo.get!(TestCoherence.User, user.id)

      assert old_password_hash == user.password_hash
      assert user.reset_password_token == nil
      assert user.reset_password_sent_at == nil
    end
  end

  describe "trackable table" do
    setup [:setup_trackable_table]

    test "reset password creates rememberable", %{conn: conn, user: user} do
      {:ok, user} = PasswordService.reset_password_token(user)
      params = %{"password" => %{"reset_password_token" => user.reset_password_token, "password" => "secret2", "password_confirmation" => "secret2", "current_password" => "supersecret"}}
      conn = put conn, password_path(conn, :update, user), params
      assert conn.private[:phoenix_flash] == %{"info" => "Password updated successfully."}
      assert html_response(conn, 302)
      [t1] = Repo.all(Trackable)
      assert t1.action == "password_reset"
      assert t1.user_id == user.id
    end

  end
end
