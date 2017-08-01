defmodule <%= user_schema %> do
  @moduledoc false
  use Ecto.Schema
  use Coherence.Schema

  <%= if use_binary_id? do %>
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  <% end %>

  schema "<%= user_table_name %>" do
    field :name, :string
    field :email, :string
    coherence_schema()

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :email] ++ coherence_fields())
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> validate_coherence(params)
  end

  def changeset(model, params, :password) do
    model
    |> cast(params, ~w(password password_confirmation reset_password_token reset_password_sent_at))
    |> validate_coherence_password_reset(params)
  end
end
