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
