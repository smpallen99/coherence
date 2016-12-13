defmodule Coherence.Supervisor do
  @doc false
  import Coherence.Authentication.Utils, only: [get_credential_store: 0]
  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    import Supervisor.Spec
    use Coherence.Config

    children = [
      worker(get_credential_store, [])
    ]
    |> build_children(Config.has_option(:rememberable))

    supervise(children, strategy: :one_for_one)
  end

  defp build_children(children, true) do
    import Supervisor.Spec
    [worker(Coherence.RememberableServer, []) | children]
  end
  defp build_children(children, _), do: children

end
