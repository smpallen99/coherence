defmodule <%= web_base %>.Coherence.PasswordController do
  @moduledoc """
  Handle password recovery actions.

  Controller that handles the recover password feature.

  Actions:

  * new - render the recover password form
  * create - verify user's email address, generate a token, and send the email
  * edit - render the reset password form
  * update - verify password, password confirmation, and update the database
  """
  use CoherenceWeb, :controller
  use Timex

  alias Coherence.{TrackableService, Messages}
  alias <%= base %>.Coherence.Schemas

  require Logger

  plug :layout_view, view: Coherence.PasswordView, caller: __MODULE__
  plug :redirect_logged_in when action in [:new, :create, :edit, :update]

  @type schema :: Ecto.Schema.t
  @type conn :: Plug.Conn.t
  @type params :: Map.t

  @doc """
  Render the recover password form.
  """
  @spec new(conn, params) :: conn
  def new(conn, _params) do
    user_schema = Config.user_schema
    changeset = Controller.changeset :password, user_schema, user_schema.__struct__
    render(conn, :new, [email: "", changeset: changeset])
  end

  @doc """
  Create the recovery token and send the email
  """
  @spec create(conn, params) :: conn
  def create(conn, %{"password" => password_params} = params) do
    user_schema = Config.user_schema
    user = Schemas.get_user_by_email(password_params["email"])

    recover_password(conn, user_schema, user, params)
  end

  @doc """
  Render the password and password confirmation form.
  """
  @spec edit(conn, params) :: conn
  def edit(conn, params) do
    user_schema = Config.user_schema
    token = params["id"]

    case Schemas.get_by_user(reset_password_token: token) do
      nil ->
        conn
        |> put_flash(:error, Messages.backend().invalid_reset_token())
        |> redirect(to: logged_out_url(conn))
      user ->
        if expired? user.reset_password_sent_at, days: Config.reset_token_expire_days do
          :password
          |> Controller.changeset(user_schema, user, clear_password_params())
          |> Schemas.update

          conn
          |> put_flash(:error, Messages.backend().password_reset_token_expired())
          |> redirect(to: logged_out_url(conn))
        else
          changeset = Controller.changeset(:password, user_schema, user)
          render(conn, "edit.html", changeset: changeset)
        end
    end
  end

  @doc """
  Verify the passwords and update the database
  """
  @spec update(conn, params) :: conn
  def update(conn, %{"password" => password_params} = params) do
    user_schema = Config.user_schema
    token = password_params["reset_password_token"]

    case Schemas.get_by_user reset_password_token: token do
      nil ->
        respond_with(
          conn,
          :password_update_error,
          %{error: Messages.backend().invalid_reset_token()}
        )
      user ->
        if expired? user.reset_password_sent_at, days: Config.reset_token_expire_days do
          :password
          |> Controller.changeset(user_schema, user, clear_password_params())
          |> Schemas.update

          respond_with(
            conn,
            :password_update_error,
            %{error: Messages.backend().password_reset_token_expired()}
          )
        else
          params = clear_password_params password_params

          :password
          |> Controller.changeset(user_schema, user, params)
          |> Schemas.update
          |> case do
            {:ok, user} ->
              conn
              |> TrackableService.track_password_reset(user, user_schema.trackable_table?)
              |> respond_with(
                :password_update_success,
                %{
                  params: params,
                  info: Messages.backend().password_updated_successfully()
                }
              )
            {:error, changeset} ->
              respond_with(
                conn,
                :password_update_error,
                %{changeset: changeset}
              )
          end
        end
    end
  end

  defp clear_password_params(params \\ %{}) do
    params
    |> Map.put("reset_password_token", nil)
    |> Map.put("reset_password_sent_at", nil)
  end

  defp recover_password(conn, user_schema, nil, params) do
    if Config.allow_silent_password_recovery_for_unknown_user do
      info = Messages.backend().reset_email_sent()

      conn
      |> respond_with( :password_create_success, %{params: params, info: info})
    else
      changeset = Controller.changeset :password, user_schema, user_schema.__struct__
      error = Messages.backend().could_not_find_that_email_address()

      conn
      |> respond_with(:password_create_error, %{changeset: changeset, error: error})
    end
  end
  defp recover_password(conn, user_schema, user, params) do
    token = random_string 48
    url = router_helpers().password_url(conn, :edit, token)
    dt = Ecto.DateTime.utc
    info = Messages.backend().reset_email_sent()

    Config.repo.update! Controller.changeset(:password, user_schema, user,
      %{reset_password_token: token, reset_password_sent_at: dt})

    conn
    |> send_email_if_mailer(info, fn -> send_user_email :password, user, url end)
    |> respond_with(:password_create_success, %{params: params, info: info})
  end
end
