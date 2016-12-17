defmodule Coherence.TrackableService do
  @moduledoc """
  Trackable tracks login information for each login.

  Use the `--trackable` installation option to enable this feature.

  Trackable adds the following fields to the user schema:

  * :sign_in_count - Increments each time a user logs in.
  * :current_sign_in_at - The time and date the user logged in.
  * :current_sign_in_ip - The IP address of the logged in user.
  * :last_sign_in_at: last_at - The previous login time and date
  * :last_sign_in_ip: last_ip - The previous login IP address
  """
  use Coherence.Config
  alias Coherence.ControllerHelpers, as: Helpers
  alias Plug.Conn
  require Logger

  @type schema :: Ecto.Schema.t
  @type conn :: Plug.Conn.t
  @type params :: Map.t

  @doc """
  Track user login details.

  Saves the ip address and timestamp when the user logs in.
  """
  @spec track_login(conn, schema, boolean) :: conn
  def track_login(conn, _, false), do: conn
  def track_login(conn, user, true) do
    ip = conn.peer |> elem(0) |> inspect
    now = Ecto.DateTime.utc
    {last_at, last_ip} = cond do
      is_nil(user.last_sign_in_at) and is_nil(user.current_sign_in_at) ->
        {now, ip}
      !!user.current_sign_in_at ->
        {user.current_sign_in_at, user.current_sign_in_ip}
      true ->
        {user.last_sign_in_at, user.last_sign_in_ip}
    end

    Helpers.changeset(:session, user.__struct__, user,
      %{
        sign_in_count: user.sign_in_count + 1,
        current_sign_in_at: Ecto.DateTime.utc,
        current_sign_in_ip: ip,
        last_sign_in_at: last_at,
        last_sign_in_ip: last_ip
      })
    |> Config.repo.update
    |> case do
      {:ok, user} -> Conn.assign conn, Config.assigns_key, user
      {:error, _changeset} ->
        Logger.error ("Failed to update tracking!")
        conn
    end
  end

  @spec track_logout(conn, schema, boolean) :: conn
  def track_logout(conn, _, false), do: conn
  def track_logout(conn, user, true) do
    Helpers.changeset(:session, user.__struct__, user,
      %{
        last_sign_in_at: user.current_sign_in_at,
        last_sign_in_ip: user.current_sign_in_ip,
        current_sign_in_at: nil,
        current_sign_in_ip: nil
      })
    |> Config.repo.update
    conn
  end

end
