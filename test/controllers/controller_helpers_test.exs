defmodule CoherenceTest.ControllerHelpers do
  use TestCoherence.ConnCase
  alias TestCoherence.User
  alias Coherence.ControllerHelpers, as: Helpers
  import TestCoherence.TestHelpers
  doctest Coherence.ControllerHelpers

  setup do
    Application.put_env :coherence, :opts, [:authenticatable, :recoverable,
      :confirmable, :invitable, :registerable]
  end

  test "confirm!" do
    user = insert_user()
    refute User.confirmed?(user)
    {:ok, user} = Helpers.confirm!(user)
    assert User.confirmed?(user)

    {:error, changeset} = Helpers.confirm!(user)
    refute changeset.valid?
    assert changeset.errors == [confirmed_at: {"already confirmed", []}]
  end

  test "lock!" do
    user = insert_user()
    refute User.locked?(user)
    {:ok, user} = Helpers.lock!(user)
    assert User.locked?(user)

    {:error, changeset} = Helpers.lock!(user)
    refute changeset.valid?
    assert changeset.errors == [locked_at: {"already locked", []}]
  end

  test "unlock!" do
    user = insert_user(%{locked_at: Ecto.DateTime.utc})
    assert User.locked?(user)
    {:ok, user} = Helpers.unlock!(user)
    refute User.locked?(user)

    {:error, changeset} = Helpers.unlock!(user)
    refute changeset.valid?
    assert changeset.errors == [locked_at: {"not locked", []}]
  end
end
