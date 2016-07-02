defmodule Coherence.Invitation do
  use Coherence.Web, :model

  schema "invitations" do
    field :name, :string
    field :email, :string
    field :token, :string

    timestamps
  end

  @required_fields ~w(name email)
  @optional_fields ~w(token)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/@/)
  end
end
