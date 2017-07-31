defmodule Coherence.CredentialStore.Server do
  # ExActor will help us simplify the definition of our GenServer
  use ExActor.GenServer, export: Coherence.CredentialStore.Server

  alias Coherence.CredentialStore.Types, as: T

  @behaviour Coherence.CredentialStore

  # Server State
  # ------------
  # The state of the server is a record containing a store and an index.
  require Record
  # The state is not part of the server's API, so its type and constructor will be private.
  # We want to have the flexibility of changing this later for efficiency reasons.
  Record.defrecordp :state, [store: %{}, index: %{}]
  # The store is a map mapping credentials to user_data
  @typep store :: %{T.credentials => T.user_data}
  # The index is a map mapping the user's id to that user's active sessions.
  @typep index :: %{T.user_id => MapSet.t(T.credentials)}
  # The index makes it much easier to find out which session credentials belong to a certain user.
  # Without this index, to get or update all sessions belonging to a user, one has to iterate over all the items in the map
  # This is linear on the number of active sessions (>= the number of users because there can be >= 1 session per user)
  # With the index, accessing all the sessions belonging to a user costs a map lookup
  # and iterating over all sessions it is linear on the number of sessions belonging to that user.
  # This is a clear improvement if there are many concurrent users.
  #
  # The costs of this index are increased memory consumption (we need to keep what's basically a duplicated state) and slower update operations.
  # For applications with many concurrent sessions, the benefits probably outweight the costs.
  # For applications without many concurrent sessions these costs aren't great anyway.

  # Public API for our server
  # -------------------------

  defstart start_link, do:
    # initially, both the store and the index are empty
    initial_state(state(store: %{}, index: %{}))

  @spec update_user_logins(T.user_data) :: [T.credentials]
  defcall update_user_logins(%{id: user_id} = user_data), state: state(store: store, index: index) do
    # TODO:
    # Maybe support updating ths user's ID.
    # Currently it's not obvious what's the best API for this.
    # -----------------------------------------
    # Get credentials for all sessions belonging to user
    # This operations is read-only for the index.
    sessions_credentials = Map.get(index, user_id, [])
    # Build the changes to apply to the store.
    # This is linear on the number of sessions belonging to the user.
    # It is much better than the naive approach without the index,
    # which is linear on the total number of active sessions.
    delta = for credentials <- sessions_credentials, into: %{}, do: {credentials, user_data}
    set_and_reply(
      # Update the store with the new user_data model
      # The index data is not touched, so the index is returned unchanged.
      state(store: Map.merge(store, delta), index: index),
      # Return the updated credentials for all sessions belonging to the user
      Map.keys(delta)
    )
  end
  defcall update_user_logins(_), do:
    # If the user_data doesn't contain an ID, there are no sessions belonging to the user
    # There is no need to update anything and we just return an empty list
    reply([])

  @spec update_user_logins(T.credentials) :: T.user_data
  defcall get_user_data(credentials), state: state(store: store) do
    Map.get(store, credentials) |> reply
  end

  @spec  put_credentials(T.credentials, T.user_data) :: T.user_data
  defcall put_credentials(credentials, user_data), state: state(store: store, index: index) do
    # The data has been changed; We must update both the index and the store
    # Update the index only if it makes sense
    possibly_updated_index = maybe_add_credentials_to_index(index, user_data, credentials)
    # Always update the store
    updated_store = add_credentials_to_store(store, user_data, credentials)
    # Update the state and reply
    set_and_reply(
      state(store: updated_store, index: possibly_updated_index),
      # Return the updated store
      user_data
    )
  end

  @spec  delete_credentials(T.credentials) :: store
  defcall delete_credentials(credentials), state: state(store: store, index: index) do
    user_data = Map.get(store, credentials)
    # The data has been changed; We must update both the index and the store
    # Update the index only if it makes sense
    possibly_updated_index = maybe_delete_credentials_from_index(index, user_data, credentials)
    # Always update the store
    updated_store = delete_credentials_from_store(store, credentials)
    set_and_reply(
      state(store: updated_store, index: possibly_updated_index),
      updated_store
    )
  end

  defcast stop, do: stop_server(:normal)

  # Helper functions:
  # -----------------
  @spec maybe_add_credentials_to_index(index, T.user_data, T.credentials) :: index
  defp maybe_add_credentials_to_index(index, %{id: user_id}, credentials), do:
    # If there isn't an entry for user_id in the index, create it.
    # If there is already an entry for user_id, append the new credentials.
    Map.update(index,
               user_id,
               # If the user has no credentials, create a new entry in the MapSet
               # with the new credentials
               MapSet.put(MapSet.new(), credentials),
               # If the user already has some credentials, put the new credential
               &(MapSet.put(&1, credentials)))      
  defp maybe_add_credentials_to_index(index, nil, _), do: index
  defp maybe_add_credentials_to_index(index, _, _), do: index

  @spec maybe_delete_credentials_from_index(index, T.user_data, T.credentials) :: index
  defp maybe_delete_credentials_from_index(index, %{id: user_id}, credentials) do
    # We must handle 3 cases:
    case index do
      %{^user_id => sessions_credentials} ->
        case MapSet.size(sessions_credentials) do
          # 1. The user has a single session
          # -----------------------------------
          # If there is only a single session belonging to that user,
          # the user is no longer active after deleting the session.
          # We can delete it from the index.
          1 -> Map.delete(index, user_id)
          # 2. The user has more than one session
          # -------------------------------------
          # We must delete the credentials from the set of session credentials
          _ -> %{index | user_id => MapSet.delete(sessions_credentials, credentials)}
        end
      # 3. The user has no sessions (return the index unchanged)
      _ -> index
    end
  end
  defp maybe_delete_credentials_from_index(index, nil, _), do: index
  defp maybe_delete_credentials_from_index(index, _, _), do: index
  

  @spec add_credentials_to_store(store, T.user_data, T.credentials) :: store
  defp add_credentials_to_store(store, user_data, credentials), do:
    Map.put(store, credentials, user_data)

  @spec delete_credentials_from_store(store, T.credentials) :: store
  defp delete_credentials_from_store(store, credentials), do:
    Map.delete(store, credentials)
end