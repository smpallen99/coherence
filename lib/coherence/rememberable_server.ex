defmodule Coherence.RememberableServer do
  @moduledoc false
  use GenServer

  @name __MODULE__

  @doc false
  def start_link, do: GenServer.start_link(__MODULE__, [], name: @name)

  @doc false
  def callback(callback) do
    GenServer.call(@name, {:callback, callback})
  end

  @doc false
  def init(_) do
    {:ok, nil}
  end

  @doc false
  def handle_call({:callback, callback}, _, state) do
    {:reply, callback.(), state}
  end

end
