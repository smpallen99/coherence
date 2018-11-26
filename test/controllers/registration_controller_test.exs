defmodule CoherenceTest.RegistrationController do
  use TestCoherence.ConnCase
  import TestCoherenceWeb.Router.Helpers

  setup %{conn: conn} = context do
    Application.put_env(:coherence, :opts, [:confirmable, :registerable])

    Application.put_env(
      :coherence,
      :confirm_email_updates,
      Map.get(context, :confirm_email_updates, false)
    )

    user = insert_user(%{name: "John Doe"})
    conn = assign(conn, :current_user, user)
    {:ok, conn: conn, user: user}
  end

  describe "show" do
    test "can visit show registration page", %{conn: conn} do
      conn = get(conn, registration_path(conn, :show))
      assert html_response(conn, 200)
      assert conn.private[:phoenix_template] == "show.html"
    end
  end

  describe "edit" do
    test "can visit edit registration page", %{conn: conn} do
      conn = get(conn, registration_path(conn, :edit))
      assert html_response(conn, 200)
      assert conn.private[:phoenix_template] == "edit.html"
    end
  end

  describe "new" do
    test "can visit new registration page", %{conn: conn} do
      conn = assign(conn, :current_user, nil)
      conn = get(conn, registration_path(conn, :new))
      assert html_response(conn, 200)
      assert conn.private[:phoenix_template] == "new.html"
    end
  end

  describe "create" do
    test "can create new registration with valid params, password_confirmation is not mandatory",
         %{conn: conn} do
      conn = assign(conn, :current_user, nil)

      params = %{
        "registration" => %{
          "name" => "John Doe",
          "email" => "john.doe@example.com",
          "password" => "123123"
        }
      }

      conn = post conn, registration_path(conn, :create), params
      assert conn.private[:phoenix_flash] == %{"error" => "Mailer configuration required!"}
      assert html_response(conn, 302)
    end

    test "password_confirmation checked only if present", %{conn: conn} do
      conn = assign(conn, :current_user, nil)

      params = %{
        "registration" => %{
          "name" => "John Doe",
          "email" => "john.doe@example.com",
          "password_confirmation" => "no match",
          "password" => "123123"
        }
      }

      conn = post conn, registration_path(conn, :create), params
      errors = conn.assigns.changeset.errors

      assert errors[:password_confirmation] ==
               {"does not match confirmation", [validation: :confirmation]}
    end

    test "can not register with invalid params", %{conn: conn} do
      conn = assign(conn, :current_user, nil)
      params = %{"registration" => %{}}
      conn = post conn, registration_path(conn, :create), params
      errors = conn.assigns.changeset.errors
      assert errors[:password] == {"can't be blank", []}
      assert errors[:email] == {"can't be blank", [validation: :required]}
      assert errors[:name] == {"can't be blank", [validation: :required]}
    end

    test "mass asignment not allowed", %{conn: conn} do
      conn = assign(conn, :current_user, nil)

      params = %{
        "registration" => %{
          "name" => "John Doe",
          "email" => "john.doe@example.com",
          "password" => "123123",
          "current_sign_in_ip" => "mass_asignment"
        }
      }

      conn = post conn, registration_path(conn, :create), params
      assert conn.private[:phoenix_flash] == %{"error" => "Mailer configuration required!"}
      assert html_response(conn, 302)

      %{:current_sign_in_ip => current_sign_in_ip} =
        get_user_by_email(params["registration"]["email"])

      refute current_sign_in_ip == params["registration"]["current_sign_in_ip"]
    end
  end

  @moduletag report: [:confirm_email_updates]
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
      params = %{
        "registration" => %{
          current_password: "123456",
          password: "123123",
          password_confirmation: "123123"
        }
      }

      conn = put conn, registration_path(conn, :update), params
      errors = conn.assigns.changeset.errors
      assert errors[:current_password] == {"invalid current password", []}
    end

    test "mass assignment not allowed", %{conn: conn, user: user} do
      params = %{
        "registration" => %{
          "current_password" => user.password,
          "current_sign_in_ip" => "mass_asignment"
        }
      }

      conn = put conn, registration_path(conn, :update), params
      assert conn.private[:phoenix_flash] == %{"info" => "Account updated successfully."}
      assert html_response(conn, 302)
      %{:current_sign_in_ip => current_sign_in_ip} = get_user_by_email(user.email)
      refute current_sign_in_ip == params["registration"]["current_sign_in_ip"]
    end

    test "can update email directly", %{conn: conn} do
      params = %{"registration" => %{"email" => "john.doe@example.com"}}
      conn = put conn, registration_path(conn, :update), params
      assert html_response(conn, 302)
      %{:email => email} = get_user_by_name("John Doe")
      assert email == params["registration"]["email"]
    end

    @tag confirm_email_updates: true
    test "cannot update email directly but unconfirmed_email", %{conn: conn} do
      params = %{"registration" => %{"email" => "john.doe@example.com"}}
      conn = put conn, registration_path(conn, :update), params
      assert html_response(conn, 302)
      user = get_user_by_name("John Doe")
      assert user.unconfirmed_email == params["registration"]["email"]
      refute user.email == params["registration"]["email"]
    end

    @tag confirm_email_updates: true
    test "should not set unconfirmed email if email is the same", %{conn: conn, user: user} do
      params = %{"registration" => %{"email" => user.email}}
      conn = put conn, registration_path(conn, :update), params
      assert html_response(conn, 302)
      user = get_user_by_name("John Doe")
      refute user.unconfirmed_email
      assert user.email == user.email
    end
  end
end
