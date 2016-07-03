defmodule Coherence.RegistrationController do
  use Coherence.Web, :controller
  require Logger

  plug Coherence.ValidateOption, :registerable
  plug :scrub_params, "registration" when action in [:create, :update]

  def new(conn, _params) do
    user_schema = Config.user_schema
    cs = user_schema.changeset(user_schema.__struct__)
    conn
    |> put_layout({Coherence.LayoutView, "app.html"})
    |> put_view(Coherence.RegistrationView)
    |> render(:new, email: "", changeset: cs)
  end

  def create(conn, %{"registration" => registration_params}) do
    user_schema = Config.user_schema
    cs = user_schema.changeset(user_schema.__struct__, registration_params)
    case Config.repo.insert(cs) do
      {:ok, user} ->
        conn
        |> send_confirmation(user, user_schema)
        |> redirect(to: logged_out_url(conn))
      {:error, changeset} ->
        conn
        |> put_layout({Coherence.LayoutView, "app.html"})
        |> put_view(Coherence.RegistrationView)
        |> render("new.html", changeset: changeset)
    end
  end

  # def delete(conn, _params) do
  #   apply(Config.auth_module, Config.delete_login, [conn])
  #   |> put_view(Admin1.LayoutView)
  #   |> redirect(to: logged_out_url(conn))
  # end

  defp send_confirmation(conn, user, user_schema) do
    if user_schema.confirmable? do
      token = random_string 48
      url = router_helpers.confirmation_url(conn, :edit, token)
      Logger.debug "confirmation email url: #{inspect url}"
      dt = Ecto.DateTime.utc
      user_schema.changeset(user,
        %{confirmation_token: token, confirmation_send_at: dt})
      |> Config.repo.update!

      email = Coherence.UserEmail.confirmation(user, url)
      Logger.debug fn -> "confirmation email: #{inspect email}" end
      email |> Coherence.Mailer.deliver

      conn
      |> put_flash(:info, "Confirmation email sent.")
    else
      conn
      |> put_flash(:info, "Registration created successfully.")
    end

  end

end
