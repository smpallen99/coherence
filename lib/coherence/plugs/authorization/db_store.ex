defprotocol Coherence.DbStore do
  @moduledoc """
  Database persistence of current_user data.

  Implement this protocol to add database storage, allowing session
  data to survive application restarts.
  """
  @fallback_to_any true

  @doc """
  Get authenticated user data.
  """
  def get_user_data(resource, credentials, id_key)

  @doc """
  Save authenticated user data in the database.
  """
  def put_credentials(resource, credentials, id_key)

  @doc """
  Delete current user credentials.
  """
  def delete_credentials(resource, credentials)
end

defimpl Coherence.DbStore, for: Any do
  require Logger
  def get_user_data(_, _, _), do: nil
  def put_credentials(_, _, _), do: nil
  def delete_credentials(_, _), do: nil
end
