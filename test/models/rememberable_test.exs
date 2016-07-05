defmodule Coherence.RememberableTest do
  use TestCoherence.ModelCase

  alias Coherence.{Rememberable, Config}

  setup do
    user = %TestCoherence.User{id: 1}
    user_schema = Config.user_schema
    Application.put_env :coherence, :user_schema, TestCoherence.User
    on_exit fn ->
      Application.put_env :coherence, :user_schema, user_schema
    end
    {:ok, user: user}
  end

  @valid_attrs %{user_id: 1, series: "1234", token: "abcd", token_created_at: "2010-04-17 14:00:00"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Rememberable.changeset(%Rememberable{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Rememberable.changeset(%Rememberable{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "create_login", %{user: user} do
    {changeset, series, token} = Rememberable.create_login(user)
    assert changeset.valid?
    assert series
    assert token
    assert {:user_id, user.id} in changeset.changes
    assert changeset.changes[:token_created_at]
    refute series == changeset.changes[:series]
    refute token == changeset.changes[:token]
  end

  test "update_login", %{user: user} do
    {%{changes: changes}, series, token} = Rememberable.create_login(user)
    :timer.sleep 1100
    {%{changes: new_changes}, new_token} = Rememberable.update_login(user)
    assert new_changes[:token_created_at]
    assert new_changes[:token]
    refute new_changes[:series]
    refute new_changes[:token_created_at] == changes[:token_created_at]
    refute new_changes[:token] == changes[:token]
  end

  def now, do: Ecto.DateTime.utc
  @now Ecto.DateTime.utc

  @rememberables [
    %Rememberable{user_id: 10, series: "123", token: "abc", token_created_at: @now},
    %Rememberable{user_id:  1, series: "123", token: "abc", token_created_at: @now},
  ]
  test "validate_login single", %{user: user} do
    {changeset, series, token} = Rememberable.create_login(user)
    r1 = build_rememberable changeset.changes
    assert Rememberable.validate_login([r1], user, series, token) == :ok

    {changeset, series, token} = Rememberable.create_login(user)
    r1 = build_rememberable changeset.changes
    assert Rememberable.validate_login([r1 | @rememberables], user, series, token) == :ok
  end
  test "validate_login theft", %{user: user} do
    {changeset, series, token} = Rememberable.create_login(user)
    r1 = build_rememberable changeset.changes
    r2 = struct(r1, token: "abc")
    assert Rememberable.validate_login([r1, r2 | @rememberables], user, series, token) == {:error, :invalid_token}
  end

  def build_rememberable(changes) do
    struct(%Rememberable{}, changes)
  end

end
