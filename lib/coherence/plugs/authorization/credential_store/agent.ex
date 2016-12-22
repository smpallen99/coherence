defmodule Coherence.CredentialStore.Agent do
  @behaviour Coherence.CredentialStore

  @type t :: Ecto.Schema.t | Map.t

  @doc """
  Starts a new credentials store.
  """
  @spec start_link() :: {:ok, pid}
  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Gets the user data for the given credentials
  """
  @spec get_user_data(Map.t) :: String.t | nil
  def get_user_data(credentials) do
    Agent.get(__MODULE__, &Map.get(&1, credentials))
  end

  @doc """
  Puts the `user_data` for the given `credentials`.
  """
  @spec put_credentials(Map.t, t) :: t
  def put_credentials(credentials, user_data) do
    Agent.update(__MODULE__, &Map.put(&1, credentials, user_data))
  end

  @doc """
  Deletes `credentials` from the store.

  Returns the current value of `credentials`, if `credentials` exists.
  """
  @spec delete_credentials(Map.t) :: t
  def delete_credentials(credentials) do
    Agent.get_and_update(__MODULE__, &Map.pop(&1, credentials))
  end

end
