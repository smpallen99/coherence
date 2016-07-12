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

  plug :layout_view

  @doc false
  def layout_view(conn, _) do
    conn
    |> put_layout({Coherence.LayoutView, "app.html"})
    |> put_view(Coherence.PasswordView)
  end

  @doc """
  Render the recover password form.
  """
  def new(conn, _params) do
    user_schema = Config.user_schema
    cs = user_schema.changeset(user_schema.__struct__)
    conn
    |> render(:new, [email: "", changeset: cs])
  end

  @doc """
  Create the recovery token and send the email
  """
  def create(conn, %{"password" => password_params}) do
    user_schema = Config.user_schema
    email = password_params["email"]
    user = where(user_schema, [u], u.email == ^email)
    |> Config.repo.one

    case user do
      nil ->
        changeset = user_schema.changeset(user_schema.__struct__)
        conn
        |> put_flash(:error, "Could not find that email address")
        |> render("new.html", changeset: changeset)
      user ->
        token = random_string 48
        url = router_helpers.password_url(conn, :edit, token)
        Logger.debug "reset email url: #{inspect url}"
        dt = Ecto.DateTime.utc
        cs = user_schema.changeset(user,
          %{reset_password_token: token, reset_password_sent_at: dt})
        Config.repo.update! cs

        send_user_email :password, user, url

        conn
        |> put_flash(:info, "Reset email send. Check your email for a reset link.")
        |> redirect(to: logged_out_url(conn))
    end
  end

  @doc """
  Render the password and password confirmation form.
  """
  def edit(conn, params) do
    user_schema = Config.user_schema
    token = params["id"]
    user = where(user_schema, [u], u.reset_password_token == ^token)
    |> Config.repo.one
    case user do
      nil ->
        conn
        |> put_flash(:error, "Invalid reset token.")
        |> redirect(to: logged_out_url(conn))
      user ->
        if expired? user.reset_password_sent_at, days: Config.reset_token_expire_days do
          clear_password_params(user, user_schema, %{})
          |> Config.repo.update

          conn
          |> put_flash(:error, "Password reset token expired.")
          |> redirect(to: logged_out_url(conn))
        else
          changeset = user_schema.changeset(user)
          conn
          |> render("edit.html", changeset: changeset)
        end
    end
  end

  @doc """
  Verify the passwords and update the database
  """
  def update(conn, %{"password" => password_params}) do
    user_schema = Config.user_schema
    repo = Config.repo
    token = password_params["reset_password_token"]
    user = where(user_schema, [u], u.reset_password_token == ^token)
    |> repo.one
    case user do
      nil ->
        conn
        |> put_flash(:error, "Invalid reset token")
        |> redirect(to: logged_out_url(conn))
      user ->
        cs = user_schema.changeset(user, password_params)
        case repo.update(cs) do
          {:ok, user} ->
            clear_password_params(user, user_schema, %{})
            |> repo.update

            conn
            |> put_flash(:info, "Password updated successfully.")
            |> redirect(to: logged_out_url(conn))
          {:error, changeset} ->
            conn
            |> render("edit.html", changeset: changeset)
        end
    end
  end

  defp clear_password_params(user, user_schema, params) do
    params = Map.put(params, "reset_password_token", nil)
    |> Map.put("reset_password_sent_at", nil)
    user_schema.changeset(user, params)
  end

end
