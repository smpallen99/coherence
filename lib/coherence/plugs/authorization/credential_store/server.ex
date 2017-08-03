defmodule Coherence.CredentialStore.Server do

  alias Coherence.CredentialStore.Types, as: T

  @name __MODULE__

  @behaviour Coherence.CredentialStore

  # Server State
  # ------------
  # The state of the server is a record containing a store and an index.
  # defstruct store: %{}, index: %{}

  ###################
  # Public API

  @spec start_link() :: {:ok, pid}
  def start_link do
    GenServer.start_link __MODULE__, [], name: @name
  end

  @spec update_user_logins(T.user_data) :: no_return
  def update_user_logins(%{id: _} = user_data) do
    GenServer.cast @name, {:update_user_logins, user_data}
  end

    # If the user_data doesn't contain an ID, there are no sessions belonging to the user
    # There is no need to update anything and we just return an empty list
  def update_user_logins(_), do: []

  @spec delete_user_logins(T.user_data) :: no_return
  def delete_user_logins(%{id: _} = user_data) do
    GenServer.cast @name, {:delete_user_logins, user_data}
  end

  @spec get_user_data(T.credentials) :: T.user_data
  def get_user_data(credentials) do
    GenServer.call @name, {:get_user_data, credentials}
  end

  @spec put_credentials(T.credentials, T.user_data) :: no_return
  def put_credentials(credentials, user_data) do
    GenServer.cast @name, {:put_credentials, credentials, user_data}
  end

  @spec delete_credentials(T.credentials) :: no_return
  def delete_credentials(credentials) do
    GenServer.cast @name, {:delete_credentials, credentials}
  end

  @spec stop() :: no_return
  def stop do
    GenServer.cast @name, :stop
  end

  ###################
  # Callbacks

  @doc false
  def init(_) do
    {:ok, initial_state()}
  end

  @doc false
  def handle_call({:get_user_data, credentials}, _from, state) do
    id = state.store[credentials]
    user_data =
      case state.user_data[id] do
        nil -> nil
        {user_data, _} -> user_data
      end
    {:reply, user_data, state}
  end

  @doc false
  def handle_cast({:put_credentials, credentials, %{id: id} = user_data}, state) do
    state =
      update_in(state, [:user_data, id], fn
        nil              -> {user_data, 1}
        {_, cnt} -> {user_data, cnt + 1}
      end)
      |> put_in([:store, credentials], id)
    {:noreply, state}
  end

  def handle_cast({:put_credentials, _credentials, _user_data}, state) do
    {:noreply, state}
  end

  @doc false
  def handle_cast({:update_user_logins, %{id: id} = user_data}, state) do
    # TODO:
    # Maybe support updating ths user's ID.
    state = update_in(state, [:user_data, id], fn {_, inx} ->
      {user_data, inx}
    end)
    {:noreply, state}
  end

  @doc false
  def handle_cast({:delete_user_logins, %{id: id}}, state) do
    state =
      state
      |> remove_all_users_from_store(id)
      |> update_in([:user_data], & Map.delete(&1, id))
    {:noreply, state}
  end

  @doc false
  def handle_cast({:delete_credentials, credentials}, state) do
    id = state.store[credentials]
    state =
      state
      |> update_in([:store], &Map.delete(&1, credentials))
      |> update_in([:user_data, id], fn
        {_, 1} -> nil
        {user_data, inx} -> {user_data, inx - 1}
      end)
    {:noreply, state}
  end

  @doc false
  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  ##################
  # Private

  defp initial_state, do: %{store: %{}, user_data: %{}}

  defp remove_all_users_from_store(state, id) do
    update_in(state, [:store], fn store ->
      for val = {_, v} <- store, v != id, into: %{}, do: val
    end)
  end

end
