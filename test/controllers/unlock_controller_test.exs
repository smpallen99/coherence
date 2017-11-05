defmodule CoherenceTest.UnlockController do
  use TestCoherence.ConnCase
  import TestCoherenceWeb.Router.Helpers
  alias Coherence.{Controller, LockableService}
  alias TestCoherence.Coherence.Trackable
  import Ecto.Query
  alias TestCoherence.{User}

  def setup_trackable_table %{conn: conn} do
    Application.put_env :coherence, :opts, [:authenticatable, :recoverable,
      :lockable, :trackable_table, :unlockable_with_token, :invitable, :registerable]
    Application.put_env(:coherence, :max_failed_login_attempts, 2)
    user = insert_user()
    {:ok, conn: conn, user: user}
  end
  def setup_controller %{conn: conn} do
    Application.put_env :coherence, :opts, [:authenticatable, :lockable, :unlockable_with_token]
    user = insert_user()
    {:ok, conn: conn, user: user}
  end

  describe "unlock controller" do
    setup [:setup_controller]

    test "POST create", %{conn: conn, user: user} do
      params = %{"unlock" => %{"password" => "supersecret", "email" => user.email}}
      conn = post conn, unlock_path(conn, :create), params
      assert html_response(conn, 302)
      user = Repo.get User, user.id
      assert user.unlock_token
    end
    test "GET edit", %{conn: conn, user: user} do
      {:ok, user} = Controller.lock!(user)
      |> elem(1)
      |> LockableService.unlock_token
      conn = get conn, unlock_path(conn, :edit, user.unlock_token)
      assert html_response(conn, 302)
    end
  end

  describe "trackable table" do
    setup [:setup_trackable_table]

    test "unlock token", %{conn: conn, user: user} do
      {:ok, user} = Controller.lock!(user)
      |> elem(1)
      |> LockableService.unlock_token
      get conn, unlock_path(conn, :edit, user.unlock_token)
      trackables = Trackable |> order_by(asc: :id) |> Repo.all
      assert Enum.count(trackables) == 1
      assert Enum.at(trackables, 0).action == "unlock_token"
    end
  end
end
