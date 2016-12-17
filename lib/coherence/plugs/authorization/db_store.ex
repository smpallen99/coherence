defprotocol Coherence.DbStore do
  @moduledoc """
  Database persistence of current_user data.

  Implement this protocol to add database storage, allowing session
  data to survive application restarts.
  """
  @fallback_to_any true

  @type schema :: Ecto.Schema.t | Map.t

  @doc """
  Get authenticated user data.
  """
  @spec get_user_data(schema, HashDict.t, atom) :: schema
  def get_user_data(resource, credentials, id_key)

  @doc """
  Save authenticated user data in the database.
  """
  @spec put_credentials(schema, HashDict.t, atom) :: schema
  def put_credentials(resource, credentials, id_key)

  @doc """
  Delete current user credentials.
  """
  @spec delete_credentials(schema, HashDict.t) :: schema
  def delete_credentials(resource, credentials)
end

defimpl Coherence.DbStore, for: Any do
  require Logger
  def get_user_data(_, _, _), do: nil
  def put_credentials(_, _, _), do: nil
  def delete_credentials(_, _), do: nil
end
