defmodule CoherenceTest.RegistrationController do
  use TestCoherence.ConnCase
  import TestCoherenceWeb.Router.Helpers

  setup %{conn: conn} do
    Application.put_env :coherence, :opts, [:confirmable, :registerable]
    user = insert_user()
    conn = assign conn, :current_user, user
    {:ok, conn: conn, user: user}
  end

  describe "show" do
    test "can visit show registraion page", %{conn: conn} do
      conn = get conn, registration_path(conn, :show)
      assert html_response(conn, 200)
      assert conn.private[:phoenix_template] == "show.html"
    end
  end

  describe "edit" do
    test "can visit edit registraion page", %{conn: conn} do
      conn = get conn, registration_path(conn, :edit)
      assert html_response(conn, 200)
      assert conn.private[:phoenix_template] == "edit.html"
    end
  end

  describe "create" do
    test "can create new registration with valid params", %{conn: conn} do
      conn = assign conn, :current_user, nil
      params = %{"registration" => %{"name" => "John Doe", "email" => "john.doe@example.com", "password" => "123123"}}
      conn = post conn, registration_path(conn, :create), params
      assert conn.private[:phoenix_flash] == %{"error" => "Mailer configuration required!"}
      assert html_response(conn, 302)
    end

    test "can not register with invalid params", %{conn: conn} do
      conn = assign conn, :current_user, nil
      params = %{"registration" => %{}}
      conn = post conn, registration_path(conn, :create), params
      errors = conn.assigns.changeset.errors
      assert errors[:password] == {"can't be blank", []}
      assert errors[:email] == {"can't be blank", [validation: :required]}
      assert errors[:name] == {"can't be blank", [validation: :required]}
    end
  end

  describe "update" do
    test "can update registration with valid current password", %{conn: conn, user: user} do
      params = %{"registration" => %{"current_password" => user.password}}
      conn = put conn, registration_path(conn, :update), params
      assert conn.private[:phoenix_flash] == %{"info" => "Account updated successfully."}
      assert html_response(conn, 302)
    end

    test "can not update registration without current password", %{conn: conn} do
      params = %{"registration" => %{password: "123123", password_confirmation: "123123"}}
      conn = put conn, registration_path(conn, :update), params
      errors = conn.assigns.changeset.errors
      assert errors[:current_password] == {"can't be blank", []}
    end

    test "can not update registration without valid current password", %{conn: conn} do
      params = %{"registration" => %{current_password: "123456", password: "123123", password_confirmation: "123123"}}
      conn = put conn, registration_path(conn, :update), params
      errors = conn.assigns.changeset.errors
      assert errors[:current_password] == {"invalid current password", []}
    end
  end
end
