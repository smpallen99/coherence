defmodule Coherence.SessionService do
  def sign_user_token(conn, user) do
    Phoenix.Token.sign(conn, "user socket", user.id)
  end

  def verify_user_token(socket, token) do
    Phoenix.Token.verify(socket, "user socket", token, max_age: 2 * 7 * 24 * 60 * 60)
  end
end
