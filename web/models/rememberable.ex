defmodule Coherence.Rememberable do
  @moduledoc false

  use Coherence.Web, :model
  use Timex

  alias Coherence.Config
  alias __MODULE__

  require Logger

  schema "rememberables" do
    field :series_hash, :string
    field :token_hash, :string
    field :token_created_at, Timex.Ecto.DateTime
    belongs_to :user, Module.concat(Config.module, Config.user_schema)

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
    |> cast(params, ~w(series_hash token_hash token_created_at user_id))
    |> validate_required(~w(series_hash token_hash token_created_at user_id)a)
  end

  @spec create_login(Ecto.Schema.t) :: {Ecto.Changeset.t, String.t, String.t}
  def create_login(user) do
    series = gen_series()
    token = gen_token()
    changeset = changeset(%__MODULE__{}, %{token_created_at: created_at(), user_id: user.id,
      series_hash: hash(series), token_hash: hash(token)})
    {changeset, series, token}
  end

  @spec update_login(Ecto.Changeset.t) :: {Ecto.Changeset.t, String.t}
  def update_login(rememberable) do
    token = gen_token()
    {changeset(rememberable, %{token_hash: hash(token)}), token}
  end

  @spec get_valid_login(integer, String.t, String.t) :: Ecto.Queryable.t
  def get_valid_login(user_id, series, token) do
    from p in Rememberable,
      where: p.user_id == ^user_id and p.series_hash == ^series and p.token_hash == ^token
  end

  @spec get_invalid_login(integer, String.t, String.t) :: Ecto.Queryable.t
  def get_invalid_login(user_id, series, token) do
    from p in Rememberable,
      where: p.user_id == ^user_id and p.series_hash == ^series and p.token_hash != ^token,
      select: count(p.id)
  end

  @spec delete_all(integer) :: Ecto.Queryable.t
  def delete_all(user_id) do
    from p in Rememberable, where: p.user_id == ^user_id
  end

  @spec delete_expired_tokens() :: Ecto.Queryable.all
  def delete_expired_tokens do
    expire_datetime = Timex.shift(Timex.now, hours: -Config.rememberable_cookie_expire_hours)
    from p in Rememberable, where: p.token_created_at < ^expire_datetime
  end

  @spec gen_cookie(integer, String.t, String.t) :: String.t
  def gen_cookie(user_id, series, token), do: "#{user_id} #{series} #{token}"

  @spec hash(String.t) :: String.t
  def hash(string) do
    :sha
    |> :crypto.hash(String.to_char_list(string))
    |> Base.url_encode64
  end

  @spec log_cookie(String.t) :: String.t
  def log_cookie(cookie) do
    [_id, series, token] = String.split cookie, " "
    cookie <> " : #{hash series}  #{hash token}"
  end

  defp created_at, do: Timex.now

  defp gen_token do
    Coherence.ControllerHelpers.random_string 24
  end
  defp gen_series do
    Coherence.ControllerHelpers.random_string 10
  end
end
