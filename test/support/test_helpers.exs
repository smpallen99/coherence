defmodule TestCoherence.TestHelpers do
  alias Coherence.{Rememberable}
  def insert_user(attrs \\ %{}) do
    changes = Dict.merge(%{
      name: "Test User",
      email: "user#{Base.encode16(:crypto.rand_bytes(8))}@example.com",
      password: "supersecret",
      password_confirmation: "supersecret"
      }, attrs)

    %TestCoherence.User{}
    |> TestCoherence.User.changeset(changes)
    |> TestCoherence.Repo.insert!
  end

  def insert_rememberable(user, attrs \\ %{}) do
    {changeset, series, token} = Rememberable.create_login(user)
    changes = changeset.changes
    changes = Dict.merge(%{
      user_id: user.id,
      series: changes[:series],
      token: changes[:token],
      token_created_at: changes[:token_created_at]
      }, attrs)
    r1 = %Rememberable{}
    |> Rememberable.changeset(changes)
    |> TestCoherence.Repo.insert!
    {r1, series, token}
  end

end
