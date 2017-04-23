defmodule Coherence.CredentialStore.Session do
  @moduledoc """
  Stores current credential information.

  Uses an Agent to save logged in credentials.

  Note: If you restart the phoenix server, this information
  is lost, requiring the user to log in again.

  If you would like to preserve login status across server restart, you
  can enable the Rememberable option, or configure the Database
  cache on the Session plug.
  """

  @doc """
  Starts a new credentials store.
  """
  @behaviour Coherence.CredentialStore

  @type t :: Ecto.Schema.t | Map.t

  require Logger
  alias Coherence.DbStore
  alias Coherence.CredentialStore.Agent

  @spec start_link() :: {:ok, pid} | {:error, atom}
  def start_link do
    Agent.start_link
  end

  @doc """
  Gets the user data for the given credentials
  """
  @spec get_user_data({HashDict.t, nil | struct, integer | nil}) :: any
  def get_user_data({credentials, nil, _}) do
    get_data credentials
  end
  def get_user_data({credentials, db_model, id_key}) do
    case get_data credentials do
      nil ->
        case DbStore.get_user_data(db_model.__struct__, credentials, id_key) do
          nil -> nil
          user_data ->
            Agent.put_credentials(credentials, user_data)
            user_data
        end
      other ->
        other
    end
  end

  defp get_data(credentials), do: Agent.get_user_data(credentials)

  @doc """
  Puts the `user_data` for the given `credentials`.
  """
  @spec put_credentials({HashDict.t, any, atom}) :: any
  def put_credentials({credentials, user_data, id_key}) do
    Agent.put_credentials(credentials, user_data)
    DbStore.put_credentials(user_data, credentials, id_key)
  end

  @doc """
  Deletes `credentials` from the store.

  Returns the current value of `credentials`, if `credentials` exists.
  """
  @spec delete_credentials(HashDict.t) :: any
  def delete_credentials(credentials) do
    case get_data credentials do
      nil -> nil
      user_data ->
        DbStore.delete_credentials user_data, credentials
        Agent.delete_credentials(credentials)
    end
  end
end
