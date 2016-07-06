defmodule Coherence.Rememberable do
  use Coherence.Web, :model
  use Timex
  alias Coherence.Config
  require Logger

  schema "rememberables" do
    field :series, :string
    field :token, :string
    field :token_created_at, Timex.Ecto.DateTime
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

  def update_login(rememberable) do
    token = gen_token
    {changeset(rememberable, %{token: hash(token)}), token}
  end

  def log_cookie(cookie) do
    [_id, series, token] = String.split cookie, " "
    cookie <> " : #{hash series}  #{hash token}"
  end

  def gen_cookie(user_id, series, token), do: "#{user_id} #{series} #{token}"

  defp created_at, do: DateTime.now

  defp gen_token do
    Coherence.ControllerHelpers.random_string 24
  end
  defp gen_series do
    Coherence.ControllerHelpers.random_string 10
  end

  def hash(string) do
    :crypto.hash(:sha, String.to_char_list(string))
    |> Base.url_encode64
  end

end
