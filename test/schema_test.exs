defmodule CoherenceTest.Schema do
  use TestCoherence.ModelCase
  alias TestCoherence.User

  setup do
    :ok
  end

  @email "schema@test.com"
  test "validates correct password" do
    cs = User.changeset(%User{}, %{email: @email, password: "12345", password_confirmation: "12345"})
    assert cs.valid?
  end

  test "invalidates incorrect password" do
    cs = User.changeset(%User{}, %{email: @email, password: "12345", password_confirmation: ""})
    refute cs.valid?
    cs = User.changeset(%User{}, %{email: @email, password: "12345", password_confirmation: "99"})
    refute cs.valid?
  end
  test "checkpw" do
    params = %{email: "schema@test.com", password: "test", password_confirmation: "test"}
    user = Repo.insert! User.changeset(%User{}, params)
    assert User.checkpw("test", user.encrypted_password)
    refute User.checkpw("t", user.encrypted_password)
  end

  test "checkpw invalid passwords" do
    refute User.checkpw("", "")
    refute User.checkpw(nil, nil)
  end


end
