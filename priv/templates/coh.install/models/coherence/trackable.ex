defmodule <%= base %>.Coherence.Trackable do
  @moduledoc """
  Schema responsible for saving user tracking data for the --trackable-table option.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Coherence.Config

  @fields ~w(action sign_in_count current_sign_in_ip current_sign_in_at last_sign_in_ip last_sign_in_at user_id)a

  <%= if use_binary_id? do %>
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  <% end %>

  schema "trackables" do
    field :action, :string, null: false
    field :sign_in_count, :integer, default: 0
    field :current_sign_in_at, :naive_datetime
    field :last_sign_in_at, :naive_datetime
    field :current_sign_in_ip, :string
    field :last_sign_in_ip, :string
    belongs_to :user, Config.user_schema()<%= if use_binary_id?, do: ", type: :binary_id", else: "" %>

    timestamps()
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  @spec changeset(Ecto.Schema.t, Map.t) :: Ecto.Changeset.t
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required([:action, :user_id])
  end

  @doc """
  Creates a changeset for a new schema
  """
  @spec new_changeset(Map.t) :: Ecto.Changeset.t
  def new_changeset(params \\ %{}) do
    changeset %__MODULE__{}, params
  end

end
