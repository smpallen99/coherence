defmodule CoherenceWeb do
  @moduledoc """
  Coherence setting for web resources.

  Similar to a project's Web module
  """

  @doc false
  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query, only: [from: 1, from: 2]

      if Coherence.Config.use_binary_id? do
        @primary_key {:id, :binary_id, autogenerate: true}
        @foreign_key_type :binary_id
      end
    end
  end

  @doc false
  def controller do
    quote do
      use Phoenix.Controller
      import Coherence.Controller
      import Ecto
      import Ecto.Query

      alias Coherence.Config
      alias Coherence.Controller

      require Redirects
    end
  end

  @doc false
  def router do
    quote do
      use Phoenix.Router
    end
  end

  def service do
    quote do
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
