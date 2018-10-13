defmodule CoherenceTest.Controller do
  use TestCoherence.ConnCase
  alias TestCoherence.User
  alias Coherence.Controller
  import TestCoherence.TestHelpers

  doctest Coherence.Controller

  setup do
    Application.put_env(:coherence, :opts, [
      :authenticatable,
      :recoverable,
      :confirmable,
      :invitable,
      :registerable
    ])
  end

  test "confirm!" do
    user = insert_user()
    refute User.confirmed?(user)
    {:ok, user} = Controller.confirm!(user)
    assert User.confirmed?(user)

    {:error, changeset} = Controller.confirm!(user)
    refute changeset.valid?
    assert changeset.errors == [confirmed_at: {"already confirmed", []}]
  end

  test "lock!" do
    user = insert_user()
    refute User.locked?(user)
    {:ok, user} = Controller.lock!(user)
    assert User.locked?(user)

    {:error, changeset} = Controller.lock!(user)
    refute changeset.valid?
    assert changeset.errors == [locked_at: {"already locked", []}]
  end

  test "unlock!" do
    user = insert_user(%{locked_at: NaiveDateTime.utc_now()})
    assert User.locked?(user)
    {:ok, user} = Controller.unlock!(user)
    refute User.locked?(user)

    {:error, changeset} = Controller.unlock!(user)
    refute changeset.valid?
    assert changeset.errors == [locked_at: {"not locked", []}]
  end

  test "permit only permitted map keys" do
    params = %{
      "id" => 1,
      "email" => "example@example.com",
      "name" => "tester",
      "password" => "super secret"
    }

    permitted = ["email", "name", "password"]

    assert %{"email" => "example@example.com", "name" => "tester", "password" => "super secret"} ==
             Controller.permit(params, permitted)
  end

  test "permit permitted and params keys do not match in type" do
    params = %{
      :id => 1,
      :email => "example@example.com",
      :name => "tester",
      :password => "super secret"
    }

    permitted = ["email", "name", "password"]
    assert %{} == Controller.permit(params, permitted)
  end

  test "permit with not defined permitted" do
    params = %{
      :id => 1,
      :email => "example@example.com",
      :name => "tester",
      :password => "super secret"
    }

    assert %{} == Controller.permit(params, nil)
  end

  test "extra permitted attribute" do
    params = %{"email" => "example@example.com", "name" => "tester", "password" => "super secret"}
    assert params == Controller.permit(params, ["extra", "email", "name", "password"])
  end
end
