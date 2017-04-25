defmodule <%= base %>.Web.Coherence.SessionController do
  @moduledoc """
  Handle the authentication actions.

  """
  use <%= base %>.Coherence.Web, :controller

  import Coherence.TrackableService
  import Coherence.Rememberable, only: [hash: 1, gen_cookie: 3]

  alias Coherence.{Rememberable}
  alias Coherence.{ConfirmableService}

  require Logger

  @type schema :: Ecto.Schema.t
  @type conn :: Plug.Conn.t
  @type params :: Map.t

  @flash_invalid dgettext("coherence", "Incorrect %{login_field} or password.", login_field: Config.login_field)
  @flash_locked dgettext("coherence", "Maximum Login attempts exceeded. Your account has been locked.")

  plug :layout_view, view: Coherence.SessionView
  plug :redirect_logged_in when action in [:new, :create]

  @doc false
  @spec login_cookie() :: String.t
  def login_cookie, do: "coherence_login"

  @doc """
  Retrieve the login cookie.
  """
  @spec get_login_cookie(conn) :: String.t
  def get_login_cookie(conn) do
    conn.cookies[Config.login_cookie]
  end

  defp rememberable_enabled? do
    if Config.user_schema.rememberable?(), do: true, else: false
  end

  @doc """
  Render the login form.
  """
  @spec new(conn, params) :: conn
  def new(conn, _params) do
    login_field = Config.login_field()
    conn
    |> put_view(Coherence.SessionView)
    |> render(:new, [{login_field, ""}, remember: rememberable_enabled?()])
  end

  @doc """
  Login the user.

  Find the user based on the login_field. Hash the given password and verify it
  matches the value stored in the database. Login proceeds only if the following
  other conditions are satisfied:

  * Confirmation is enabled and the user has been confirmed.
  * Lockable is enabled and the user is not locked.

  If the Trackable option is enabled, the trackable fields are update.

  If the provided password is not correct, and the lockable option is enabled check
  to see if the maximum login attempts threshold is exceeded. If so, lock the account.

  If the rememberable option is enabled, create a new series and rememberable token,
  create a new cookie and update the database.
  """
  @spec create(conn, params) :: conn
  def create(conn, params) do
    user_schema = Config.user_schema()
    lockable? = user_schema.lockable?()
    login_field = Config.login_field()
    login_field_str = to_string login_field
    login = params["session"][login_field_str]
    password = params["session"]["password"]
    remember = if Config.user_schema.rememberable?(), do: params["remember"], else: false
    user = Config.repo.one(from u in user_schema, where: field(u, ^login_field) == ^login)
    if user != nil and user_schema.checkpw(password, Map.get(user, Config.password_hash())) do
      if ConfirmableService.confirmed?(user) || ConfirmableService.unconfirmed_access?(user) do
        do_lockable(conn, login_field, [user, user_schema, remember, lockable?, remember, params],
          user_schema.lockable?() and user_schema.locked?(user))
      else
        conn
        |> put_flash(:error, dgettext("coherence", "You must confirm your account before you can login."))
        |> put_status(406)
        |> render("new.html", [{login_field, login}, remember: rememberable_enabled?()])
      end
    else
      conn
      |> track_failed_login(user, user_schema.trackable_table?())
      |> failed_login(user, lockable?)
      |> put_status(401)
      |> render(:new, [{login_field, login}, remember: rememberable_enabled?()])
    end
  end

  defp do_lockable(conn, login_field, _, true) do
    conn
    |> put_flash(:error, dgettext("coherence", "Too many failed login attempts. Account has been locked."))
    |> assign(:locked, true)
    |> put_status(423)
    |> render("new.html", [{login_field, ""}, remember: rememberable_enabled?()])
  end

  defp do_lockable(conn, _login_field, opts, false) do
    [user, user_schema, remember, lockable?, remember, params] = opts
    conn = if lockable? && user.locked_at() do
      Helpers.unlock!(user)
      track_unlock conn, user, user_schema.trackable_table?()
    else
      conn
    end
    Config.auth_module()
    |> apply(Config.create_login(), [conn, user, [id_key: Config.schema_key()]])
    |> reset_failed_attempts(user, lockable?)
    |> track_login(user, user_schema.trackable?(), user_schema.trackable_table?())
    |> save_rememberable(user, remember)
    |> put_flash(:notice, dgettext("coherence", "Signed in successfully."))
    |> redirect_to(:session_create, params)
  end

  @doc """
  Logout the user.

  Delete the user's session, track the logout and delete the rememberable cookie.
  """
  @spec delete(conn, params) :: conn
  def delete(conn, params) do
    conn
    |> logout_user
    |> redirect_to(:session_delete, params)
  end

  # @doc """
  # Delete the user session.
  # """
  # def delete(conn) do
  #   user = conn.assigns[Config.assigns_key()]
  #   Config.auth_module()
  #   |> apply(Config.delete_login(), [conn])
  #   |> track_logout(user, user.__struct__.trackable?())
  #   |> delete_rememberable(user)
  # end

  defp log_lockable_update({:error, changeset}) do
    lockable_failure changeset
  end
  defp log_lockable_update(_), do: :ok

  @spec reset_failed_attempts(conn, Ecto.Schema.t, boolean) :: conn
  def reset_failed_attempts(conn, %{failed_attempts: attempts} = user, true) when attempts > 0 do
    :session
    |> Helpers.changeset(user.__struct__, user, %{failed_attempts: 0})
    |> Config.repo.update
    |> log_lockable_update
    conn
  end
  def reset_failed_attempts(conn, _user, _), do: conn

  defp failed_login(conn, %{} = user, true) do
    attempts = user.failed_attempts + 1
    {conn, flash, params} =
      if attempts >= Config.max_failed_login_attempts() do
        new_conn =
          conn
          |> assign(:locked, true)
          |> track_lock(user, user.__struct__.trackable_table?())
        {new_conn, @flash_locked, %{locked_at: Ecto.DateTime.utc()}}
      else
        {conn, @flash_invalid, %{}}
      end
    :session
    |> Helpers.changeset(user.__struct__, user, Map.put(params, :failed_attempts, attempts))
    |> Config.repo.update
    |> log_lockable_update

    put_flash(conn, :error, flash)
  end
  defp failed_login(conn, _user, _), do: put_flash(conn, :error, @flash_invalid)

  @doc """
  Call back for the authentication plug.

  Render the login form.
  """
  @spec login_callback(conn) :: conn
  def login_callback(conn) do
    conn = if Map.get conn.private, "phoenix_layout" do
      conn
    else
      put_layout conn, Config.layout({Coherence.LayoutView, :app})
    end

    conn
    |> new(%{})
    |> halt
  end

  @doc """
  Callback for the authenticate plug.

  Validate the rememberable cookie. If valid, generate a new token,
  keep the same series number. Update the rememberable database with
  the new token. Save the new cookie.
  """
  @spec rememberable_callback(conn, integer, String.t, String.t, Keyword.t) :: conn
  def rememberable_callback(conn, id, series, token, opts) do
    Coherence.RememberableServer.callback fn ->
      do_rememberable_callback(conn, id, series, token, opts)
    end
  end

  @doc false
  def do_rememberable_callback(conn, id, series, token, opts) do
    case validate_login(id, series, token) do
      {:ok, rememberable} ->
        # Logger.debug "Valid login :ok"
        Config.user_schema()
        |> Config.repo().get(id)
        |> do_valid_login(conn, [id, rememberable, series, token], opts)
      {:error, :not_found} ->
        Logger.debug "No valid login found"
        {conn, nil}
      {:error, :invalid_token} ->
        # this is a case of potential fraud
        Logger.warn "Invalid token. Potential Fraud."

        conn
        |> delete_req_header(opts[:login_key])
        |> put_flash(:error, dgettext("coherence", """
          You are using an invalid security token for this site! This security
          violation has been logged.
          """))
        |> redirect(to: logged_out_url(conn))
        |> halt
    end
  end

  defp do_valid_login(nil, _conn, _parms, _opts),
    do: {:error, :not_found}
  defp do_valid_login(user, conn, params, opts) do
    [id, rememberable, series, token] = params
    cred_store = Coherence.Authentication.Utils.get_credential_store()
    if Config.async_rememberable?() and Enum.any?(conn.req_headers,
      fn {k,v} -> k == "x-requested-with" and v == "XMLHttpRequest" end) do
      # for ajax requests, we don't update the sequence number, ensuring that
      # multiple concurrent ajax requests don't fail on the seq_no
      {assign(conn, :remembered, true), user}
    else
      id
      |> gen_cookie(series, token)
      |> cred_store.delete_credentials
      {changeset, new_token} = Rememberable.update_login(rememberable)

      cred_store.put_credentials({gen_cookie(id, series, new_token), Config.user_schema(), Config.schema_key()})

      Config.repo.update! changeset

      conn =
        conn
        |> save_login_cookie(id, series, new_token, opts)
        |> assign(:remembered, true)

      {conn, user}
    end
  end

  @doc """
  Save the login cookie.
  """
  @spec save_login_cookie(conn, Integer.t, String.t, String.t, Keyword.t) :: conn
  def save_login_cookie(conn, id, series, token, opts \\ []) do
    key = opts[:login_key] || "coherence_login"
    expire = opts[:cookie_expire] || (2 * 24 * 60 * 60)
    put_resp_cookie conn, key, gen_cookie(id, series, token), max_age: expire
  end

  defp save_rememberable(conn, _user, none) when none in [nil, false], do: conn
  defp save_rememberable(conn, user, _) do
    {changeset, series, token} = Rememberable.create_login(user)
    Config.repo().insert! changeset
    opts = [
      login_key: Config.login_cookie(),
      cookie_expire: Config.rememberable_cookie_expire_hours() * 60 * 60
    ]
    save_login_cookie conn, user.id, series, token, opts
  end

  @doc """
  Fetch a rememberable database record.
  """
  @spec get_rememberables(integer) :: [schema]
  def get_rememberables(id) do
    Rememberable
    |> where([u], u.user_id == ^id)
    |> Config.repo.all
  end

  @doc """
  Validate the login cookie.

  Check the following conditions:

  * a record exists for the user, the series, but a different token
    * assume a fraud case
    * remove the rememberable cookie and delete the session
  * a record exists for the user, the series, and the token
    * a valid remembered user
  * otherwise, this is an unknown user.
  """
  @spec validate_login(integer, String.t, String.t) :: {:ok, schema} | {:error, atom}
  def validate_login(user_id, series, token) do
    hash_series = hash series
    hash_token = hash token
    repo = Config.repo()

    # TODO: move this to the RememberableServer. But first, we need to change the
    #       logic below to ignore expired tokens
    delete_expired_tokens!(repo)

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
    repo.delete_all Rememberable.delete_expired_tokens()
  end

end
