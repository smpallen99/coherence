defmodule CoherenceTest.LockableService do
  use TestCoherence.ConnCase
  alias Coherence.LockableService, as: Service

  setup %{conn: conn} do
    user = insert_user()
    {:ok, %{conn: conn, user: user}}
  end

  test "create token", %{user: user} do
    {:ok, user} = Service.unlock_token(user)
    assert user.unlock_token
  end
end
