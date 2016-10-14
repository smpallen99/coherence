defmodule Coherence.Supervisor do
  @doc false
  import Coherence.Authentication.Utils, only: [get_credential_store: 0]
  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    import Supervisor.Spec


    children = [
      worker(get_credential_store, [])
    ]
    supervise(children, strategy: :one_for_one)
  end

end
