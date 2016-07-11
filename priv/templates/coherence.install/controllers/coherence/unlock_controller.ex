defmodule <%= base %>.Coherence.UnlockController do
  use Coherence.Web, :controller
  require Logger
  use Timex
  use Coherence.Config

  plug Coherence.ValidateOption, :unlockable_with_token
  plug :layout_view

  def layout_view(conn, _) do
    conn
    |> put_layout({Coherence.LayoutView, "app.html"})
    |> put_view(Coherence.UnlockView)
  end

  def new(conn, _params) do
    user_schema = Config.user_schema
    changeset = user_schema.changeset(user_schema.__struct__)
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"unlock" => unlock_params}) do
    user_schema = Config.user_schema
    token = random_string 48
    url = router_helpers.unlock_url(conn, :edit, token)
    email = unlock_params["email"]
    password = unlock_params["password"]

    user = where(user_schema, [u], u.email == ^email)
    |> Config.repo.one

    if user != nil and user_schema.checkpw(password, Map.get(user, Config.password_hash)) do
      user_schema.changeset(user, %{unlock_token: token})
      |> Config.repo.update
      |> case do
        {:ok, _} ->
          if user_schema.locked?(user) do
            # email = Coherence.UserEmail.unlock(user, url)
            # Logger.debug fn -> "unlock email: #{inspect email}" end
            # email |> Coherence.Mailer.deliver
            send_user_email :unlock, user, url
            conn
            |> put_flash(:info, "Unlock Instructions sent.")
            |> redirect(to: logged_out_url(conn))
          else
            conn
            |> put_flash(:error, "Your account is not locked.")
            |> redirect(to: logged_out_url(conn))
          end
        {:error, changeset} ->
          render conn, "new.html", changeset: changeset
      end
    else
      conn
      |> put_flash(:error, "Invalid email or password.")
      |> redirect(to: logged_out_url(conn))
    end
  end

  def edit(conn, params) do
    user_schema = Config.user_schema
    token = params["id"]
    where(user_schema, [u], u.unlock_token == ^token)
    |> Config.repo.one
    |> case do
      nil ->
        conn
        |> put_flash(:error, "Invalid unlock token.")
        |> redirect(to: logged_out_url(conn))
      user ->
        if user_schema.locked? user do
          user_schema.unlock! user
          conn
          |> put_flash(:info, "Your account has been unlocked")
          |> redirect(to: logged_out_url(conn))
        else
          clear_unlock_values(user, user_schema)
          conn
          |> put_flash(:error, "Account is not locked.")
          |> redirect(to: logged_out_url(conn))
        end
    end
  end

  @lockable_failure "Failed to update lockable attributes "

  def clear_unlock_values(user, user_schema) do
    if user.unlock_token or user.locked_at do
      user_schema.changeset(user, %{unlock_token: nil, locked_at: nil})
      |> Config.repo.update
      |> case do
        {:error, changeset} ->
          lockable_failure changeset
        _ -> :ok
      end
    end
  end
end
