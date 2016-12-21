defmodule Coherence.TrackableService do
  @moduledoc """
  Trackable tracks login information for each login.

  You have two choices to track logins.

  1. Add trackable fields to your user schema.
  2. Create a separate trackable table.

  # User Schema Trackable Fields

  Use the `--trackable` installation option to enable this feature.

  Trackable adds the following fields to the user schema:

  * :sign_in_count - Increments each time a user logs in.
  * :current_sign_in_at - The time and date the user logged in.
  * :current_sign_in_ip - The IP address of the logged in user.
  * :last_sign_in_at: last_at - The previous login time and date
  * :last_sign_in_ip: last_ip - The previous login IP address

  # Trackable Table

  This feature provides full audit capability around user logins.

  Use the `--trackable-table installation option to use a separate trackable table/schema.

  Trackable-table creates a Trackable schema with the following fields:

  * :action - The action that generated the entry. Values are `:login, :logout, :password_reset, :failed_login, :lock, :unlock, :unlock_token`
  * :sign_in_count - Increments each time a user logs in.
  * :current_sign_in_at - The time and date the user logged in.
  * :current_sign_in_ip - The IP address of the logged in user.
  * :last_sign_in_at: last_at - The previous login time and date
  * :last_sign_in_ip: last_ip - The previous login IP address

  Note, the `--trackable` and `--trackable-table` installation options are
  mutually exclusive.
  """
  use Coherence.Config
  alias Coherence.ControllerHelpers, as: Helpers
  alias Plug.Conn
  require Logger
  require Ecto.Query
  import Ecto.Query
  alias Coherence.Trackable

  @type schema :: Ecto.Schema.t
  @type conn :: Plug.Conn.t
  @type params :: Map.t

  @doc """
  Track user login details.

  Saves the ip address and timestamp when the user logs in.

  A value of true in the third argument indicates that the `:trackable option`
  is configured. A Value of true in the fourth argument indicates that the
  `:trackable_table` is configured.
  """
  @spec track_login(conn, schema, boolean, boolean) :: conn
  def track_login(conn, _, false, false), do: conn
  def track_login(conn, user, true, false) do
    {last_at, last_ip, ip, _now} = last_at_and_ip(conn, user)

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
  def track_login(conn, user, false, true) do
    trackable = last_trackable(user.id)
    {last_at, last_ip, ip, _now} = last_at_and_ip(conn, trackable)
    Helpers.changeset(:session, Trackable, %Trackable{},
      %{
        action: "login",
        sign_in_count: trackable.sign_in_count + 1,
        current_sign_in_at: Ecto.DateTime.utc,
        current_sign_in_ip: ip,
        last_sign_in_at: last_at,
        last_sign_in_ip: last_ip,
        user_id: user.id
      })
    |> Config.repo.insert
    |> case do
      {:ok, _user} -> nil
      {:error, changeset} ->
        Logger.error ("Failed to update tracking! #{inspect changeset.errors}")
    end
    conn
  end
  @doc """
  Track user logout.

  Updates the `last_sign_in_at` and `last_sign_in_at` fields. Clears the
  'current_sign_in_at` and current_sign_in_ip' fields.

  A value of true in the third argument indicates that the `:trackable option`
  is configured. A Value of true in the fourth argument indicates that the
  `:trackable_table` is configured.
  """
  @spec track_logout(conn, schema, boolean, boolean) :: conn
  def track_logout(conn, _, false, false), do: conn
  def track_logout(conn, user, true, false) do
    Helpers.changeset(:session, user.__struct__, user,
      %{
        last_sign_in_at: user.current_sign_in_at,
        last_sign_in_ip: user.current_sign_in_ip,
        current_sign_in_at: nil,
        current_sign_in_ip: nil
      })
    |> Config.repo.update!
    conn
  end
  def track_logout(conn, user, false, true) do
    trackable = last_trackable(user.id)
    Helpers.changeset(:session, Trackable, trackable,
      %{
        last_sign_in_at: trackable.current_sign_in_at,
        last_sign_in_ip: trackable.current_sign_in_ip,
        current_sign_in_at: nil,
        current_sign_in_ip: nil,
      })
    |> Config.repo.update!

    Helpers.changeset(:session, Trackable, %Trackable{},
      %{
        action: "logout",
        sign_in_count: trackable.sign_in_count,
        last_sign_in_at: trackable.current_sign_in_at,
        last_sign_in_ip: trackable.current_sign_in_ip,
        current_sign_in_at: nil,
        current_sign_in_ip: nil,
        user_id: user.id
      })
    |> Config.repo.insert!
    conn
  end

  @spec track_password_reset(conn, schema, boolean) :: conn
  def track_password_reset(conn, _user, false), do: conn
  def track_password_reset(conn, user, true) do
    track(conn, user, "password_reset")
  end

  @spec track_failed_login(conn, schema, boolean) :: conn
  def track_failed_login(conn, _user, false), do: conn
  def track_failed_login(conn, user, true) do
    track(conn, user, "failed_login")
  end

  @spec track_lock(conn, schema, boolean) :: conn
  def track_lock(conn, _user, false), do: conn
  def track_lock(conn, user, true) do
    track(conn, user, "lock")
  end

  @spec track_unlock(conn, schema, boolean) :: conn
  def track_unlock(conn, _user, false), do: conn
  def track_unlock(conn, user, true) do
    track(conn, user, "unlock")
  end

  @spec track_unlock_token(conn, schema, boolean) :: conn
  def track_unlock_token(conn, _user, false), do: conn
  def track_unlock_token(conn, user, true) do
    track(conn, user, "unlock_token")
  end

  ##############
  # Private

  defp track(conn, user, action) do
    trackable = last_trackable(user.id)
    Helpers.changeset(:session, Trackable, %Trackable{},
      %{
        action: action,
        sign_in_count: trackable.sign_in_count,
        last_sign_in_at: trackable.last_sign_in_at,
        last_sign_in_ip: trackable.last_sign_in_ip,
        user_id: user.id
      })
    |> Config.repo.insert!
    conn
  end

  defp last_at_and_ip(conn, schema) do
    now = Ecto.DateTime.utc
    ip = conn.peer |> elem(0) |> inspect
    cond do
      is_nil(schema.last_sign_in_at) and is_nil(schema.current_sign_in_at) ->
        {now, ip, ip, now}
      !!schema.current_sign_in_at ->
        {schema.current_sign_in_at, schema.current_sign_in_ip, ip, now}
      true ->
        {schema.last_sign_in_at, schema.last_sign_in_ip, ip, now}
    end
  end

  defp last_trackable(user_id) do
    where(Trackable, [t], t.user_id == ^user_id)
    |> order_by(desc: :id)
    |> limit(1)
    |> Config.repo.one
    |> case do
      nil -> %Trackable{}
      trackable -> trackable
    end
  end

end
