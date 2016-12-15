defmodule CoherenceTest do
  use TestCoherence.ModelCase
  doctest Coherence
  alias TestCoherence.User

  test "creates a user" do
    changeset = User.changeset(%User{}, %{name: "test", email: "test@example.com", password: "test", password_confirmation: "test"})
    user = Repo.insert! changeset
    assert user.email == "test@example.com"
  end
end
