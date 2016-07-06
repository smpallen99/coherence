defmodule Coherence.RememberableTest do
  use TestCoherence.ModelCase
  use Timex

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
    {%{changes: changes}, _series, _token} = Rememberable.create_login(user)
    {%{changes: new_changes}, _new_token} =
      build_rememberable(changes)
      |> Rememberable.update_login
    assert new_changes[:token]
    refute new_changes[:series]
    refute new_changes[:token] == changes[:token]
  end

  def now, do: DateTime.now

  def rememberables, do: [
    %Rememberable{user_id: 10, series: "123", token: "abc", token_created_at: now},
    %Rememberable{user_id:  1, series: "123", token: "abc", token_created_at: now },
  ]
  @dt Timex.shift DateTime.now, months: -2
  @expired_list [
    %Rememberable{user_id: 10, series: "124", token: "abca", token_created_at: @dt},
    %Rememberable{user_id:  1, series: "12345", token: "abcd", token_created_at: @dt },
    %Rememberable{user_id:  1, series: "12", token: "ab", token_created_at: @dt },
  ]

  def build_rememberable(changes) do
    struct(%Rememberable{}, changes)
  end

end
