defmodule Coherence.SessionService do
  @moduledoc """
  Support functions for Coherence sessions.
  """
  require Coherence.Config, as: Config

  @doc """
  Create a signed Phoenix token for a given user
  """
  def sign_user_token(context, user, opts \\ []) do
    Phoenix.Token.sign(context, Config.token_salt(), user.id, opts)
  end

  @doc """
  Verify a signed Phoenix Token.
  """
  def verify_user_token(context, token, opts \\ []) do
    Phoenix.Token.verify(
      context,
      Config.token_salt(),
      token,
      Keyword.put_new(opts, :max_age, Config.token_max_age())
    )
  end
end
