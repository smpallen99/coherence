defmodule Coherence.SessionController do
  use Coherence.Web, :controller
  use Timex
  require Logger
  alias Coherence.{Config, Rememberable}
  import Ecto.Query
  import Rememberable, only: [hash: 1, gen_cookie: 3]


  def login_cookie, do: "coherence_login"

  def get_login_cookie(conn) do
    conn.cookies[Config.login_cookie]
  end

  defp rememberable_enabled? do
    if Config.user_schema.rememberable?, do: true, else: false
  end

  def new(conn, _params) do
    # if cookie = get_login_cookie(conn) do
    #   Logger.debug "Found cookie #{Rememberable.log_cookie cookie}"
    # end
    conn
    |> put_layout({Coherence.LayoutView, "app.html"})
    |> put_view(Coherence.SessionView)
    |> render(:new, [email: "", remember: rememberable_enabled?])
  end

  def create(conn, params) do
    remember = if Config.user_schema.rememberable?, do: params["remember"], else: false
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
          apply(Config.auth_module, Config.create_login, [conn, user, [id_key: Config.schema_key]])
          |> reset_failed_attempts(user, lockable?)
          |> track_login(user, user_schema.trackable?)
          |> put_flash(:notice, "Signed in successfully.")
          |> put_session("user_return_to", nil)
          |> save_rememberable(user, remember)
          |> redirect(to: url)
        else
          conn
          |> put_flash(:error, "Too many failed login attempts. Account has been locked.")
          |> assign(:locked, true)
          |> render("new.html", email: "", remember: rememberable_enabled?)
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
      |> render(:new, email: email, remember: rememberable_enabled?)
    end
  end

  def delete(conn, _params) do
    user = conn.assigns[Config.assigns_key]
    apply(Config.auth_module, Config.delete_login, [conn])
    |> track_logout(user, user.__struct__.trackable?)
    |> delete_rememberable(user)
    |> redirect(to: logged_out_url(conn))
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

  def delete_rememberable(conn, %{id: id}) do
    if Config.has_option :rememberable do
      where(Rememberable, [u], u.user_id == ^id)
      |> Config.repo.delete_all
      conn
      |> delete_resp_cookie(Config.login_cookie)
    else
      conn
    end
  end

  def login_callback(conn) do
    new(conn, %{})
    |> halt
  end

  def confirmed?(user) do
    if Config.user_schema.confirmable? do
      Config.user_schema.confirmed?(user)
    else
      true
    end
  end

  def remberable_callback(conn, id, series, token, opts) do
    repo = Config.repo
    cred_store = Coherence.Authentication.Utils.get_credential_store
    validate_login(id, series, token)
    |> case do
      {:ok, rememberable} ->
        # Logger.debug "Valid login :ok"
        user = case repo.get(Config.user_schema, id) do
          nil -> {:error, :not_found}
          user ->
            gen_cookie(id, series, token)
            |> cred_store.delete_credentials
            {changeset, new_token} = Rememberable.update_login(rememberable)

            cred_store.put_credentials({gen_cookie(id, series, new_token), Config.user_schema, Config.schema_key})

            Config.repo.update! changeset
            conn = save_login_cookie(conn, id, series, new_token, opts[:login_key], opts[:cookie_expire])
            |> assign(:remembered, true)
            {conn, user}
        end
      {:error, :not_found} ->
        Logger.debug "No valid login found"
        {conn, nil}
      {:error, :invalid_token} ->
        # this is a case of potential fraud
        Logger.warn "Invalid token. Potential Fraud."

        conn
        |> delete_req_header(opts[:login_key])
        |> put_flash(:error, """
          You are using an invalid security token for this site! This security
          violation has been logged.
          """)
        |> redirect(to: logged_out_url(conn))
        |> halt
    end
  end

  def save_login_cookie(conn, id, series, token, key \\ "coherence_login", expire \\ 2*24*60*60) do
    put_resp_cookie conn, key, gen_cookie(id, series, token), max_age: expire
  end

  defp save_rememberable(conn, _user, nil), do: conn
  defp save_rememberable(conn, user, _) do
    {changeset, series, token} = Rememberable.create_login(user)
    Config.repo.insert! changeset
    save_login_cookie conn, user.id, series, token, Config.login_cookie, Config.rememberable_cookie_expire_hours * 60 * 60
  end

  def get_rememberables(id) do
    where(Rememberable, [u], u.user_id == ^id)
    |> Config.repo.all
  end

  def validate_login(user_id, series, token) do
    hash_series = hash series
    hash_token = hash token
    repo = Config.repo
    # Logger.debug "user_id: #{user_id}, series: #{series}, token: #{token}"
    # Logger.debug "           hash_series: #{hash_series}, hash_token: #{hash_token}"

    delete_expired_tokens!(repo)   # TODO: move the following to an task

    with :ok <- get_invalid_login!(repo, user_id, hash_series, hash_token),
         {:ok, rememberable} <- get_valid_login!(repo, user_id, hash_series, hash_token),
           do: {:ok, rememberable}
  end

  defp get_invalid_login!(repo, user_id, series, token) do
    case repo.one Rememberable.get_invalid_login(user_id, series, token) do
      0 -> :ok
      _ ->
        repo.delete_all Rememberable.delete_all(user_id)
        {:error, :invalid_token}
    end
  end

  defp get_valid_login!(repo, user_id, series, token) do
    case repo.one Rememberable.get_valid_login(user_id, series, token) do
      nil   -> {:error, :not_found}
      item  -> {:ok, item}
    end
  end

  defp delete_expired_tokens!(repo) do
    repo.delete_all Rememberable.delete_expired_tokens
  end
end
