defmodule CoherenceTest.PasswordService do
  use TestCoherence.ConnCase
  alias Coherence.PasswordService, as: Service

  setup %{conn: conn} do
    user = insert_user()
    {:ok, %{conn: conn, user: user}}
  end

  test "create token", %{user: user} do
    {:ok, user} = Service.reset_password_token(user)
    assert user.reset_password_token
    assert user.reset_password_sent_at
  end
end
