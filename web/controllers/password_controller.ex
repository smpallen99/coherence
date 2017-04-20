defmodule Coherence.PasswordController do
  @moduledoc """
  Handle password recovery actions.

  Controller that handles the recover password feature.

  Actions:

  * new - render the recover password form
  * create - verify user's email address, generate a token, and send the email
  * edit - render the reset password form
  * update - verify password, password confirmation, and update the database
  """
  use Coherence.Web, :controller
  require Logger
  use Timex
  alias Coherence.ControllerHelpers, as: Helpers
  alias Coherence.TrackableService

  plug :layout_view
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
    cs = Helpers.changeset :password, user_schema, user_schema.__struct__
    conn
    |> render(:new, [email: "", changeset: cs])
  end

  @doc """
  Create the recovery token and send the email
  """
  @spec create(conn, params) :: conn
  def create(conn, %{"password" => password_params} = params) do
    user_schema = Config.user_schema
    email = password_params["email"]
    user =
      user_schema
      |> where([u], u.email == ^email)
      |> Config.repo.one

    case user do
      nil ->
        changeset = Helpers.changeset :password, user_schema, user_schema.__struct__
        conn
        |> put_flash(:error, dgettext("coherence", "Could not find that email address"))
        |> render("new.html", changeset: changeset)
      user ->
        token = random_string 48
        url = router_helpers().password_url(conn, :edit, token)
        Logger.debug "reset email url: #{inspect url}"
        dt = Ecto.DateTime.utc
        cs = Helpers.changeset(:password, user_schema, user,
          %{reset_password_token: token, reset_password_sent_at: dt})
        Config.repo.update! cs

        send_user_email :password, user, url

        conn
        |> put_flash(:info, dgettext("coherence", "Reset email sent. Check your email for a reset link."))
        |> redirect_to(:password_create, params)
    end
  end

  @doc """
  Render the password and password confirmation form.
  """
  @spec edit(conn, params) :: conn
  def edit(conn, params) do
    user_schema = Config.user_schema
    token = params["id"]
    user =
      user_schema
      |> where([u], u.reset_password_token == ^token)
      |> Config.repo.one
    case user do
      nil ->
        conn
        |> put_flash(:error, dgettext("coherence", "Invalid reset token."))
        |> redirect(to: logged_out_url(conn))
      user ->
        if expired? user.reset_password_sent_at, days: Config.reset_token_expire_days do
          :password
          |> Helpers.changeset(user_schema, user, clear_password_params())
          |> Config.repo.update

          conn
          |> put_flash(:error, dgettext("coherence", "Password reset token expired."))
          |> redirect(to: logged_out_url(conn))
        else
          changeset = Helpers.changeset(:password, user_schema, user)
          conn
          |> render("edit.html", changeset: changeset)
        end
    end
  end

  @doc """
  Verify the passwords and update the database
  """
  @spec update(conn, params) :: conn
  def update(conn, %{"password" => password_params} = params) do
    user_schema = Config.user_schema
    repo = Config.repo
    token = password_params["reset_password_token"]
    user =
      user_schema
      |> where([u], u.reset_password_token == ^token)
      |> repo.one
    case user do
      nil ->
        conn
        |> put_flash(:error, dgettext("coherence", "Invalid reset token"))
        |> redirect(to: logged_out_url(conn))
      user ->
        if expired? user.reset_password_sent_at, days: Config.reset_token_expire_days do
          Helpers.changeset(:password, user_schema, user, clear_password_params())
          |> Config.repo.update

          conn
          |> put_flash(:error, dgettext("coherence", "Password reset token expired."))
          |> redirect(to: logged_out_url(conn))
        else
          params = password_params
          |> clear_password_params
          cs = Helpers.changeset(:password, user_schema, user, params)
          case repo.update(cs) do
            {:ok, user} ->
              conn
              |> TrackableService.track_password_reset(user, user_schema.trackable_table?)
              |> put_flash(:info, dgettext("coherence", "Password updated successfully."))
              |> redirect_to(:password_update, params)
            {:error, changeset} ->
              conn
              |> render("edit.html", changeset: changeset)
          end
        end
    end
  end

  defp clear_password_params(params \\ %{}) do
    params
    |> Map.put("reset_password_token", nil)
    |> Map.put("reset_password_sent_at", nil)
  end
end
