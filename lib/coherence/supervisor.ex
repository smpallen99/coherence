defmodule Coherence.Supervisor do
  use Supervisor

  @moduledoc """
  Supervisor to start Coherence services.

  Starts the configured credential store server. Also starts
  the RememberableServer if this option is configured.
  """

  import Coherence.Authentication.Utils, only: [get_credential_store: 0]

  @doc false
  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    use Coherence.Config

    children =
      [
        {get_credential_store(), []}
      ]
      |> build_children(Config.has_option(:rememberable))

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp build_children(children, true) do
    [{Coherence.RememberableServer, []} | children]
  end

  defp build_children(children, _), do: children
end
