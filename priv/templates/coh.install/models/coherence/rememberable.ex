defmodule <%= base %>.Coherence.Rememberable do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Coherence.Config

  <%= if use_binary_id? do %>
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  <% end %>

  schema "rememberables" do
    field :series_hash, :string
    field :token_hash, :string
    field :token_created_at, :naive_datetime
    belongs_to :user, Config.user_schema()<%= if use_binary_id?, do: ", type: :binary_id", else: "" %>

    timestamps()
  end

  use Coherence.Rememberable

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  @spec changeset(Ecto.Schema.t, Map.t) :: Ecto.Changeset.t
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(series_hash token_hash token_created_at user_id))
    |> validate_required(~w(series_hash token_hash token_created_at user_id)a)
  end

  @doc """
  Creates a changeset for a new schema
  """
  @spec new_changeset(Map.t) :: Ecto.Changeset.t
  def new_changeset(params \\ %{}) do
    changeset %Rememberable{}, params
  end

end
