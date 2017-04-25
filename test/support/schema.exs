defmodule TestCoherence.User do
  use Ecto.Schema
  use Coherence.Schema

  import Ecto.Changeset

  schema "users" do
    coherence_schema()

    field :email, :string
    field :name, :string
    timestamps()
  end

  @required_fields ~w(email name)a
  @optional_fields ~w() ++ coherence_fields()

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
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

defmodule TestCoherence.Invitation do
  use Ecto.Schema
  use Coherence.Schema
  import Ecto.Changeset

  schema "invitations" do
    field :email, :string
    field :name, :string
    field :token, :string

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(name email token))
    |> validate_required([:name, :email])
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/@/)
  end
end

defmodule TestCoherence.Account do
  use Ecto.Schema
  use Coherence.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :email, :string
    field :name, :string
    coherence_schema()

    timestamps()
  end

  @required_fields ~w(email name)a
  @optional_fields ~w() ++ coherence_fields()

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:email)
    |> validate_coherence(params)
  end

  def changeset(model, params, :password) do
    model
    |> cast(params, ~w(password password_confirmation reset_password_token reset_password_sent_at))
    |> validate_coherence_password_reset(params)
  end
end

defmodule TestCoherence.Rememberable do
  use Ecto.Schema
  use Coherence.Schema
  import Ecto.Changeset
  alias Coherence.Config

  schema "rememberables" do
    field :series_hash, :string
    field :token_hash, :string
    field :token_created_at, Timex.Ecto.DateTime
    belongs_to :user, Module.concat(Config.module, Config.user_schema)
    timestamps()
  end

  @required_fields ~w(series_hash token_hash token_created_at user_id)a
  @optional_fields ~w()

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
