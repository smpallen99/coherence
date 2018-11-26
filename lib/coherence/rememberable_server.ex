defmodule Coherence.RememberableServer do
  @moduledoc false
  use GenServer
  use Coherence.Config

  @name __MODULE__

  @doc false
  def start_link, do: GenServer.start_link(__MODULE__, [], name: @name)

  @doc false
  def callback(callback) do
    GenServer.call(@name, {:callback, callback})
  end

  @doc false
  def init(_) do
    # the item below can be used to schedule expired tokens, but the
    # session controller needs to be refactored to ignore expired tokens

    # schedule_daily_work()
    {:ok, nil}
  end

  @doc false
  def handle_call({:callback, callback}, _, state) do
    {:reply, callback.(), state}
  end

  # @doc false
  # def handle_info(:daily_work, state) do
  #   # start the timer again before doing the work
  #   # this will reduce drift if the work takes a while
  #   schedule_daily_work()
  #   # do the work
  #   repo = Config.repo
  #   repo.delete_all Coherence.Rememberable.delete_expired_tokens
  #   {:noreply, state}
  # end

  # defp schedule_daily_work do
  #   Process.send_after(self(), :daily_work, 24 * 60 * 60 * 1000)  # 1 day
  # end

end
