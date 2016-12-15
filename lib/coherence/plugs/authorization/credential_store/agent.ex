defmodule Coherence.CredentialStore.Agent do
  @behaviour Coherence.CredentialStore

  @type t :: Ecto.Schema.t | Map.t

  @doc """
  Starts a new credentials store.
  """
  @spec start_link() :: {:ok, pid}
  def start_link do
    Agent.start_link(&HashDict.new/0, name: __MODULE__)
  end

  @doc """
  Gets the user data for the given credentials
  """
  @spec get_user_data(String.t) :: String.t
  def get_user_data(credentials) do
    Agent.get(__MODULE__, &HashDict.get(&1, credentials))
  end

  @doc """
  Puts the `user_data` for the given `credentials`.
  """
  @spec put_credentials(String.t, t) :: t
  def put_credentials(credentials, user_data) do
    Agent.update(__MODULE__, &HashDict.put(&1, credentials, user_data))
  end

  @doc """
  Deletes `credentials` from the store.

  Returns the current value of `credentials`, if `credentials` exists.
  """
  @spec delete_credentials(String.t) :: t
  def delete_credentials(credentials) do
    Agent.get_and_update(__MODULE__, &HashDict.pop(&1, credentials))
  end

end
