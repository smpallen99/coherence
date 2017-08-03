defmodule Coherence.CredentialStore.Server.Test do
  use ExUnit.Case, async: true

  alias Coherence.CredentialStore.Server

  setup do
    {:ok, state: initial_state(), user_data: %{id: 1, name: "A"}}
  end

  test "put and get", %{state: state, user_data: user_data} do
    creds = uuid()
    state = put_credentials state, creds, user_data
    {_, user_data1} = get_user_data state, creds
    assert user_data == user_data1
  end

  test "delete", %{state: state, user_data: user_data} do
    creds = uuid()
    state = put_credentials state, creds, user_data
    state = delete_credentials state, creds
    {_, ud} = get_user_data state, creds
    refute ud
  end

  test "put 2 and get2", %{state: state, user_data: user_data1} do
    user_data2 = %{id: 2, name: "B"}
    creds1 = uuid()
    creds2 = uuid()

    state = put_credentials state, creds1, user_data1
    state = put_credentials state, creds2, user_data2
    {state, ud1} = get_user_data state, creds1
    assert ud1 == user_data1
    {_, ud2} = get_user_data state, creds2
    assert ud2 == user_data2
  end

  test "put 2 and get2 the same", %{state: state, user_data: user_data1} do
    creds1 = uuid()
    creds2 = uuid()

    state = put_credentials state, creds1, user_data1
    state = put_credentials state, creds2, user_data1
    {state, ud1} = get_user_data state, creds1
    assert ud1 == user_data1
    {_, ud2} = get_user_data state, creds2
    assert ud2 == user_data1
  end

  test "put 2 the same delete", %{state: state, user_data: user_data1} do
    creds1 = uuid()
    creds2 = uuid()

    state = put_credentials state, creds1, user_data1
    state = put_credentials state, creds2, user_data1
    state = delete_credentials state, creds1
    {state, ud1} = get_user_data state, creds1
    refute ud1
    {state, ud1} = get_user_data state, creds2
    assert ud1 == user_data1
    state = delete_credentials state, creds2
    {_, ud} = get_user_data state, creds2
    refute ud
  end

  test "update_user_logins", %{state: state, user_data: user_data1} do
    user_data2 = %{id: 2, name: "B"}
    user_data11 = Map.put(user_data1, :name, "AA")
    creds1 = uuid()
    creds2 = uuid()
    creds3 = uuid()

    state = put_credentials state, creds1, user_data1
    state = put_credentials state, creds2, user_data1
    state = put_credentials state, creds3, user_data2
    state = update_user_logins state, user_data11

    {state, ud1} = get_user_data state, creds1
    assert ud1 == user_data11
    {_, ud2} = get_user_data state, creds2
    assert ud2 == user_data11
    {_, ud3} = get_user_data state, creds3
    assert ud3 == user_data2
  end

  test "delete_user_logins", %{state: state, user_data: user_data1} do
    user_data2 = %{id: 2, name: "B"}
    creds1 = uuid()
    creds2 = uuid()
    creds3 = uuid()

    state = put_credentials state, creds1, user_data1
    state = put_credentials state, creds2, user_data2
    state = put_credentials state, creds3, user_data1

    state = delete_user_logins state, user_data1

    {_, ud1} = get_user_data state, creds1
    refute ud1
    {_, ud2} = get_user_data state, creds2
    assert ud2 == user_data2
    {_, ud3} = get_user_data state, creds3
    refute ud3
  end


  ###############
  # Helpers

  defp uuid, do: UUID.uuid1

  defp put_credentials(state, credentials, user_data) do
    {:noreply, state1} =
      Server.handle_cast({:put_credentials, credentials, user_data}, state)
    state1
  end

  defp delete_credentials(state, credentials) do
    {:noreply, state1} =
      Server.handle_cast({:delete_credentials, credentials}, state)
    state1
  end

  defp get_user_data(state, credentials) do
    {:reply, data, state1} =
      Server.handle_call({:get_user_data, credentials}, nil, state)
    {state1, data}
  end

  defp update_user_logins(state, user_data) do
    {:noreply, state1} =
      Server.handle_cast({:update_user_logins, user_data}, state)
    state1
  end

  defp delete_user_logins(state, user_data) do
    {:noreply, state1} =
      Server.handle_cast({:delete_user_logins, user_data}, state)
    state1
  end

  defp initial_state do
    {:ok, state} = Server.init nil
    state
  end
end
