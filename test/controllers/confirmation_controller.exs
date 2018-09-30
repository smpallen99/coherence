defmodule CoherenceTest.ConfirmationController do
  use TestCoherence.ConnCase
  import TestCoherenceWeb.Router.Helpers

  setup %{conn: conn} do
    Application.put_env :coherence, :opts, [:confirmable, :registerable]
    user = %TestCoherence.User{
      name: "John Doe",
      email: "user@example.com",
      password_hash: "superhash",
      unconfirmed_email: "unconfirmed@example.com",
      confirmation_token: "foobar",
      confirmation_sent_at: Timex.now
    } |> TestCoherence.Repo.insert!
    {:ok, conn: conn, user: user}
  end

  describe "edit" do
    test "should confirm valid confirmation token", %{conn: conn} do
      conn = get conn, confirmation_path(conn, :edit, "foobar")
      assert html_response(conn, 302)
      user = get_user_by_email("user@example.com")
      assert user.confirmation_token == nil
      refute user.confirmed_at == nil
    end

    test "should set email from unconfirmed_email if confirm_email_updates is true", %{conn: conn} do
      Application.put_env :coherence, :confirm_email_updates, true
      conn = get conn, confirmation_path(conn, :edit, "foobar")
      assert html_response(conn, 302)
      user = get_user_by_email("unconfirmed@example.com")
      assert user.unconfirmed_email == nil
      assert user.confirmation_token == nil
      refute user.confirmed_at == nil
    end

    test "should not set email from unconfirmed_email if confirm_email_updates is false", %{conn: conn} do
      Application.put_env :coherence, :confirm_email_updates, false
      conn = get conn, confirmation_path(conn, :edit, "foobar")
      assert html_response(conn, 302)
      user = get_user_by_email("user@example.com")
      refute user.unconfirmed_email == nil
      assert user.confirmation_token == nil
      refute user.confirmed_at == nil
    end
  end
end
