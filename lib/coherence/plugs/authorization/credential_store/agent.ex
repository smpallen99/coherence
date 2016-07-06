defmodule Coherence.CredentialStore.Agent do
  @behaviour Coherence.CredentialStore

  @doc """
  Starts a new credentials store.
  """
  def start_link do
    Agent.start_link(&HashDict.new/0, name: __MODULE__)
  end

  @doc """
  Gets the user data for the given credentials
  """
  def get_user_data(credentials) do
    Agent.get(__MODULE__, &HashDict.get(&1, credentials))
  end

  @doc """
  Puts the `user_data` for the given `credentials`.
  """
  def put_credentials(credentials, user_data) do
    Agent.update(__MODULE__, &HashDict.put(&1, credentials, user_data))
  end

  @doc """
  Deletes `credentials` from the store.

  Returns the current value of `credentials`, if `credentials` exists.
  """
  def delete_credentials(credentials) do
    Agent.get_and_update(__MODULE__, &HashDict.pop(&1, credentials))
  end

end
