defmodule CoherenceTest.Schema do
  use TestCoherence.ModelCase
  alias TestCoherence.User

  setup do
    :ok
  end

  @email "schema@test.com"
  @valid_params %{name: "test", email: @email, password: "12345", password_confirmation: "12345"}

  test "validates correct password" do
    cs = User.changeset(%User{}, %{name: "test", email: @email, password: "12345", password_confirmation: "12345"})
    assert cs.valid?
  end

  test "invalidates incorrect password" do
    cs = User.changeset(%User{}, %{name: "test", email: @email, password: "12345", password_confirmation: ""})
    refute cs.valid?
    cs = User.changeset(%User{}, %{name: "test", email: @email, password: "12345", password_confirmation: "99"})
    refute cs.valid?
  end
  test "checkpw" do
    params = %{name: "test", email: "schema@test.com", password: "test", password_confirmation: "test"}
    user = Repo.insert! User.changeset(%User{}, params)
    assert User.checkpw("test", user.password_hash)
    refute User.checkpw("t", user.password_hash)
  end

  test "checkpw invalid passwords" do
    refute User.checkpw("", "")
    refute User.checkpw(nil, nil)
  end

  test "enforces password" do
    cs = User.changeset(%User{}, %{name: "test", email: @email})
    refute cs.valid?
  end

  test "does not require password on update" do
    user = struct %User{}, Map.put(@valid_params, :password_hash, "123")
    cs = User.changeset(user, %{name: "test123", email: @email})
    assert cs.valid?
  end

end
