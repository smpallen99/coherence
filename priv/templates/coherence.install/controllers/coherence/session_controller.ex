defmodule <%= base %>.Coherence.SessionController do
  use Coherence.Web, :controller
  require Logger

  def new(conn, _params) do
    conn
    |> put_layout({Coherence.LayoutView, "app.html"})
    |> put_view(Coherence.SessionView)
    |> render(:new, [email: ""])
  end

  def create(conn, params) do
    user_schema = Config.user_schema
    email = params["session"]["email"]
    password = params["session"]["password"]
    user = Config.repo.one(from u in user_schema, where: u.email == ^email)
    lockable? = user_schema.lockable?
    if user != nil and user_schema.checkpw(password, user.encrypted_password) do
      if confirmed? user do
        url = case get_session(conn, "user_return_to") do
          nil -> "/"
          value -> value
        end
        unless lockable? and user_schema.locked?(user) do
          # |> Coherence.Authentication.Database.create_login(user, Config.schema_key )
          apply(Config.auth_module, Config.create_login, [conn, user, Config.schema_key])
          |> reset_failed_attempts(user, lockable?)
          |> track_login(user, user_schema.trackable?)
          |> put_flash(:notice, "Signed in successfully.")
          |> put_session("user_return_to", nil)
          |> redirect(to: url)
        else
          conn
          |> put_flash(:error, "Too many failed login attempts. Account has been locked.")
          |> assign(:locked, true)
          |> render("new.html", email: "")
        end
      else
        conn
        |> put_flash(:error, "You must confirm your account before you can login.")
        |> redirect(to: logged_out_url(conn))
      end
    else
      conn
      |> failed_login(user, lockable?)
      |> put_layout({Coherence.LayoutView, "app.html"})
      |> put_view(Coherence.SessionView)
      |> render(:new, email: email)
    end
  end

  defp track_login(conn, _, false), do: conn
  defp track_login(conn, user, true) do
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

    user.__struct__.changeset(user,
      %{
        sign_in_count: user.sign_in_count + 1,
        current_sign_in_at: Ecto.DateTime.utc,
        current_sign_in_ip: ip,
        last_sign_in_at: last_at,
        last_sign_in_ip: last_ip
      })
    |> Config.repo.update
    |> case do
      {:ok, _} -> nil
      {:error, _changeset} ->
        Logger.error ("Failed to update tracking!")
    end
    conn
  end

  defp track_logout(conn, _, false), do: conn
  defp track_logout(conn, user, true) do
    user.__struct__.changeset(user,
      %{
        last_sign_in_at: user.current_sign_in_at,
        last_sign_in_ip: user.current_sign_in_ip,
        current_sign_in_at: nil,
        current_sign_in_ip: nil
      })
    |> Config.repo.update
    conn
  end

  @flash_invalid "Incorrect email or password."
  @flash_locked "Maximum Login attempts exceeded. Your account has been locked."

  defp log_lockable_update({:error, changeset}) do
    lockable_failure changeset
  end
  defp log_lockable_update(_), do: :ok

  def reset_failed_attempts(conn, %{failed_attempts: attempts} = user, true) when attempts > 0 do
    user.__struct__.changeset(user, %{failed_attempts: 0})
    |> Config.repo.update
    |> log_lockable_update
    conn
  end
  def reset_failed_attempts(conn, _user, _), do: conn

  defp failed_login(conn, %{} = user, true) do
    attempts = user.failed_attempts + 1
    {conn, flash, params} =
      if attempts >= Config.max_failed_login_attempts do
        new_conn = assign(conn, :locked, true)
        {new_conn, @flash_locked, %{locked_at: Ecto.DateTime.utc}}
      else
        {conn, @flash_invalid, %{}}
      end

    user.__struct__.changeset(user, Map.put(params, :failed_attempts, attempts))
    |> Config.repo.update
    |> log_lockable_update

    put_flash(conn, :error, flash)
  end
  defp failed_login(conn, _user, _), do: put_flash(conn, :error, @flash_invalid)

  def delete(conn, _params) do
    user = conn.assigns[:authenticated_user]
    apply(Config.auth_module, Config.delete_login, [conn])
    |> track_logout(user, user.__struct__.trackable?)
    |> redirect(to: logged_out_url(conn))
  end

  def login_callback(conn) do
    conn
    |> put_layout({Coherence.LayoutView, "app.html"})
    |> put_view(Coherence.SessionView)
    |> render("new.html", email: "")
    |> halt
  end

  def confirmed?(user) do
    if Config.user_schema.confirmable? do
      Config.user_schema.confirmed?(user)
    else
      true
    end
  end

end
