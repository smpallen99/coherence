defmodule CoherenceTest.Schema do
  use TestCoherence.ModelCase
  alias TestCoherence.User
  use Timex

  setup do
    :ok
  end

  @email "schema@test.com"
  @valid_params %{name: "test", email: @email, password: "12345", password_confirmation: "12345"}

  test "invalid email" do
    cs1 = User.changeset(%User{}, %{name: "test", email: "john-example.com", password: "12345", password_confirmation: "12345"})
    cs2 = User.changeset(%User{}, %{name: "test", email: "john.doe-example.com", password: "12345", password_confirmation: "12345"})
    refute cs1.valid?
    refute cs2.valid?
  end

  test "valid email" do
    cs1 = User.changeset(%User{}, %{name: "test", email: "john@example.com", password: "12345", password_confirmation: "12345"})
    cs2 = User.changeset(%User{}, %{name: "test", email: "john.doe@example.com", password: "12345", password_confirmation: "12345"})
    assert cs1.valid?
    assert cs2.valid?
  end

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

  test "invalidates incorrect password length" do
    cs = User.changeset(%User{}, %{name: "test", email: @email, password: "123", password_confirmation: "123"})
    refute cs.valid?
    assert cs.errors == [password: {"should be at least %{count} character(s)", [count: 4, validation: :length, min: 4]}]
  end

  test "checkpw" do
    params = %{name: "test", email: @email, password: "test", password_confirmation: "test"}
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

  test "confirmed?" do
    refute User.confirmed?(%User{})
    assert User.confirmed?(%User{confirmed_at: NaiveDateTime.utc_now()})
  end

  test "confirm" do
    changeset = User.confirm(%User{confirmation_token: "1234"})
    assert changeset.changes[:confirmed_at]
    refute changeset.changes[:confimrmation_token]
  end

  test "locked?" do
    refute User.locked?(%User{})
    assert User.locked?(%User{locked_at: NaiveDateTime.utc_now()})
  end
end
