defmodule <%= base %>.Coherence.Invitation do
  @moduledoc """
  Schema to support inviting a someone to create an account.
  """
  use Ecto.Schema
  import Ecto.Changeset

  <%= if use_binary_id? do %>
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  <% end %>

  schema "invitations" do
    field :name, :string
    field :email, :string
    field :token, :string

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
    |> cast(params, ~w(name email token))
    |> validate_required([:name, :email])
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/@/)
  end

  @doc """
  Creates a changeset for a new schema
  """
  @spec new_changeset(Map.t) :: Ecto.Changeset.t
  def new_changeset(params \\ %{}) do
    changeset %__MODULE__{}, params
  end
end
