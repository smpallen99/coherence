defprotocol Coherence.DbStore do
  @fallback_to_any true
  def get_user_data(resource, credentials, id_key)
  def put_credentials(resource, credentials, id_key)
  def delete_credentials(resource, credentials)
end

defimpl Coherence.DbStore, for: Any do
  require Logger
  def get_user_data(_, _, _), do: nil
  def put_credentials(_, _, _), do: nil
  def delete_credentials(_, _), do: nil
end
