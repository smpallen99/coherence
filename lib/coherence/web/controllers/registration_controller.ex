defmodule Coherence.RegistrationController do
  use Phoenix.Controller
  alias Coherence.Config
  import Ecto.Query

  plug :scrub_params, "registration" when action in [:create, :update]

  def new(conn, _params) do
    user_schema = Config.user_schema
    cs = user_schema.changeset(user_schema.__struct__)
    conn
    |> put_layout({Coherence.CoherenceView, "app.html"})
    |> put_view(Coherence.RegistrationView)
    |> render(:new, [email: "", changeset: cs])
  end

  def create(conn, %{"registration" => registration_params}) do
    user_schema = Config.user_schema
    cs = user_schema.changeset(user_schema.__struct__, registration_params)
    case Config.repo.insert(cs) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Registration created successfully.")
        |> redirect(to: logged_out_url(conn))
      {:error, changeset} ->
        conn
        |> put_layout({Coherence.CoherenceView, "app.html"})
        |> put_view(Coherence.RegistrationView)
        |> render("new.html", changeset: changeset)
    end
  end

  def delete(conn, _params) do
    apply(Config.auth_module, Config.delete_login, [conn])
    |> put_view(Admin1.LayoutView)
    |> redirect(to: logged_out_url(conn))
  end

  def logged_out_url(conn) do
    Config.logged_out_url || Module.concat(Config.module, Router.Helpers).session_path(conn, :new)
  end

end
