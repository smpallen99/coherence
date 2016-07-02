defmodule Coherence.PasswordController do
  use Phoenix.Controller
  alias Coherence.Config
  import Ecto.Query
  import Coherence.ControllerHelpers
  require Logger
  use Timex

  plug :layout_view

  def layout_view(conn, _) do
    conn
    |> put_layout({Coherence.CoherenceView, "app.html"})
    |> put_view(Coherence.PasswordView)
  end

  def new(conn, _params) do
    user_schema = Config.user_schema
    cs = user_schema.changeset(user_schema.__struct__)
    conn
    |> render(:new, [email: "", changeset: cs])
  end

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

        email = Coherence.UserEmail.password(user, url)
        Logger.debug fn -> "password reset email: #{inspect email}" end
        email |> Coherence.Mailer.deliver

        conn
        |> put_flash(:info, "Reset email send. Check your email for a reset link.")
        |> redirect(to: logged_out_url(conn))
    end
  end

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
        if expired? user.reset_password_sent_at do
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

  def update(conn, %{"password" => password_params}) do
    user_schema = Config.user_schema
    token = password_params["reset_password_token"]
    user = where(user_schema, [u], u.reset_password_token == ^token)
    |> Config.repo.one
    case user do
      nil ->
        conn
        |> put_flash(:error, "Invalid reset token")
        |> redirect(to: logged_out_url(conn))
      user ->
        cs = clear_password_params(user, user_schema, password_params)
        case Config.repo.update(cs) do
          {:ok, user} ->
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

  def expired?(datetime) do
    expire_on? = datetime
    |> Ecto.DateTime.to_erl
    |> Timex.DateTime.from_erl
    |> Timex.shift(days: Config.reset_token_expire_days)
    not Timex.before?(Timex.DateTime.now, expire_on?)
  end

end
