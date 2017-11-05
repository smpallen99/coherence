defmodule Coherence.RememberableTest do
  use TestCoherence.ModelCase
  use Timex

  alias Coherence.Config
  alias TestCoherence.Coherence.Rememberable

  setup do
    user = %TestCoherence.User{id: 1}
    user_schema = Config.user_schema
    Application.put_env :coherence, :user_schema, TestCoherence.User
    on_exit fn ->
      Application.put_env :coherence, :user_schema, user_schema
    end
    {:ok, user: user}
  end

  @test_date Timex.parse!("2010-04-17 14:00:00", "%Y-%m-%d %H:%M:%S", :strftime) |> Timex.to_datetime
  @valid_attrs %{user_id: 1, series_hash: "1234", token_hash: "abcd", token_created_at: @test_date}
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
    refute series == changeset.changes[:series_hash]
    refute token == changeset.changes[:token_hash]
  end

  test "update_login", %{user: user} do
    {%{changes: changes}, _series, _token} = Rememberable.create_login(user)
    {%{changes: new_changes}, _new_token} =
      build_rememberable(changes)
      |> Rememberable.update_login
    assert new_changes[:token_hash]
    refute new_changes[:series_hash]
    refute new_changes[:token_hash] == changes[:token_hash]
  end

  def now, do: Timex.now

  def rememberables, do: [
    %Rememberable{user_id: 10, series_hash: "123", token_hash: "abc", token_created_at: now()},
    %Rememberable{user_id:  1, series_hash: "123", token_hash: "abc", token_created_at: now()},
  ]

  def build_rememberable(changes) do
    struct(%Rememberable{}, changes)
  end

end
