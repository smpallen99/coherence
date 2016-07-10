defmodule TestCoherence.User do
  use Ecto.Schema
  use Coherence.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :name, :string
    coherence_schema

    timestamps
  end

  @required_fields ~w(email name)
  @optional_fields ~w() ++ coherence_fields

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:email)
    |> validate_coherence(params)
  end
end
defmodule TestCoherence.Account do
  use Ecto.Schema
  use Coherence.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :email, :string
    field :name, :string
    coherence_schema

    timestamps
  end

  @required_fields ~w(email name)
  @optional_fields ~w() ++ coherence_fields

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:email)
    |> validate_coherence(params)
  end
end

defmodule TestCoherence.Rememberable do
  use Coherence.Web, :model
  alias Coherence.Config

  schema "rememberables" do
    field :series_hash, :string
    field :token_hash, :string
    field :token_created_at, Timex.Ecto.DateTime
    belongs_to :user, Module.concat(Config.module, Config.user_schema)
    timestamps
  end

  @required_fields ~w(series_hash token_hash token_created_at user_id)
  @optional_fields ~w()

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
