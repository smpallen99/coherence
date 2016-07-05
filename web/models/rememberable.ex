defmodule Coherence.Rememberable do
  use Coherence.Web, :model
  alias Coherence.Config

  schema "rememberables" do
    field :series, :string
    field :token, :string
    field :token_created_at, Ecto.DateTime
    belongs_to :user, Module.concat(Config.module, Config.user_schema)

    timestamps
  end

  @required_fields ~w(series token token_created_at user_id)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def create_login(user) do
    series = gen_series
    token = gen_token
    changeset = changeset(%__MODULE__{}, %{token_created_at: created_at, user_id: user.id,
      series: hash(series), token: hash(token)})
    {changeset, series, token}
  end

  def update_login(user) do
    token = gen_token
    changeset = changeset(%__MODULE__{}, %{token_created_at: created_at, user_id: user.id, token: hash(token)})
    {changeset, token}
  end

  def validate_login(rememberables, %{id: id} = user, series, token) do
    validate_login(rememberables, id, series, token)
  end
  def validate_login(rememberables, user_id, series, token) when is_binary(user_id) do
    validate_login(rememberables, String.to_integer(user_id), series, token)
  end
  def validate_login(rememberables, user_id, series, token) do
    hashed_series = hash series
    rememberables
    |> Enum.filter(fn item -> item.user_id == user_id and item.series == hashed_series end)
    |> check_tokens(hash(token))
  end

  defp check_tokens([], _token) do
    {:error, :not_found}
  end
  defp check_tokens(rememberables, token) do
    Enum.filter(rememberables, &(&1.token != token))
    |> return_result
  end
  defp return_result([]), do: :ok
  defp return_result([item]), do: {:error, :invalid_token}

  defp created_at, do: Ecto.DateTime.utc

  defp gen_token do
    Coherence.ControllerHelpers.random_string 24
  end
  defp gen_series do
    Coherence.ControllerHelpers.random_string 10
  end

  defp hash(string) do
    :crypto.hash(:sha, String.to_char_list(string))
    |> Base.url_encode64
  end

end
