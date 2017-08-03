defmodule Coherence.Rememberable do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      use Timex

      alias Coherence.Config
      alias __MODULE__

      require Logger

      @spec create_login(Ecto.Schema.t) :: {Ecto.Changeset.t, String.t, String.t}
      def create_login(user) do
        series = gen_series()
        token = gen_token()
        changeset = changeset(%Rememberable{}, %{token_created_at: created_at(), user_id: user.id,
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
        |> :crypto.hash(String.to_charlist(string))
        |> Base.url_encode64
      end

      @spec log_cookie(String.t) :: String.t
      def log_cookie(cookie) do
        [_id, series, token] = String.split cookie, " "
        cookie <> " : #{hash series}  #{hash token}"
      end

      def created_at, do: Timex.now

      def gen_token do
        Coherence.Controller.random_string 24
      end
      def gen_series do
        Coherence.Controller.random_string 10
      end

      defoverridable [
        create_login: 1, update_login: 1, get_valid_login: 3, delete_all: 1,
        delete_expired_tokens: 0, gen_cookie: 3, hash: 1, log_cookie: 1,
        created_at: 0, gen_series: 0, gen_token: 0
      ]

    end
  end
end
