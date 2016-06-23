defmodule TestCoherence.User do
  use Ecto.Schema
  use Coherence.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :encrypted_password, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
  end

  @required_fields ~w(email)
  @optional_fields ~w(encrypted_password password password_confirmation)

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:email)
    |> validate_password(params)
  end
end
