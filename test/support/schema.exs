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

defmodule TestCoherence.Coherence.User do
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

defmodule TestCoherence.Coherence.Invitation do
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

  def new_changeset(params \\ %{}) do
    changeset __MODULE__.__struct__, params
  end
end

defmodule TestCoherence.Coherence.Account do
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

defmodule TestCoherence.Coherence.Rememberable do
  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset

  alias Coherence.Config

  schema "rememberables" do
    field :series_hash, :string
    field :token_hash, :string
    field :token_created_at, :naive_datetime
    belongs_to :user, Config.user_schema
    timestamps()
  end

  use Coherence.Rememberable

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(series_hash token_hash token_created_at user_id))
    |> validate_required(~w(series_hash token_hash token_created_at user_id)a)
  end

  def new_changeset(params \\ %{}) do
    changeset %Rememberable{}, params
  end
end

defmodule TestCoherence.Coherence.Trackable do
  @moduledoc """
  Schema responsible for saving user tracking data for the --trackable-table option.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Coherence.Config

  @fields ~w(action sign_in_count current_sign_in_ip current_sign_in_at last_sign_in_ip last_sign_in_at user_id)a

  schema "trackables" do
    field :action, :string, null: false
    field :sign_in_count, :integer, default: 0
    field :current_sign_in_at, :naive_datetime
    field :last_sign_in_at, :naive_datetime
    field :current_sign_in_ip, :string
    field :last_sign_in_ip, :string
    belongs_to :user, Config.user_schema

    timestamps()
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required([:action, :user_id])
  end

  @doc """
  Creates a changeset for a new schema
  """
  def new_changeset(params \\ %{}) do
    changeset %__MODULE__{}, params
  end

end
