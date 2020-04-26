defmodule Coherence.Supervisor do
  @moduledoc """
  Supervisor to start Coherence services.

  Starts the configured credential store server. Also starts
  the RememberableServer if this option is configured.
  """
  use Supervisor

  import Coherence.Authentication.Utils, only: [get_credential_store: 0]

  @doc false
  def child_spec(args),
    do: %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, args},
      restart: :permanent,
      shutdown: 500,
      type: :supervisor
    }

  @doc false
  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(_) do
    use Coherence.Config

    [{get_credential_store(), []}]
    |> build_children(Config.has_option(:rememberable))
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp build_children(children, true), do: [{Coherence.RememberableServer, []} | children]
  defp build_children(children, _), do: children
end
