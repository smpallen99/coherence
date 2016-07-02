defmodule Coherence.SessionController do
  use Phoenix.Controller
  alias Coherence.Config
  import Ecto.Query
  import Coherence.ControllerHelpers

  def new(conn, _params) do
    conn
    |> put_layout({Coherence.CoherenceView, "app.html"})
    |> put_view(Coherence.SessionView)
    |> render(:new, [email: ""])
  end

  def create(conn, params) do
    user_schema = Config.user_schema
    email = params["session"]["email"]
    password = params["session"]["password"]
    u = Config.repo.one(from u in user_schema, where: u.email == ^email)
    # Logger.warn "user: #{inspect u}"
    if u != nil and user_schema.checkpw(password, u.encrypted_password) do
      if confirmed? u do
        url = case get_session(conn, "user_return_to") do
          nil -> "/"
          value -> value
        end
        # |> Coherence.Authentication.Database.create_login(u, Config.schema_key )
        apply(Config.auth_module, Config.create_login, [conn, u, Config.schema_key])
        |> put_flash(:notice, "Signed in successfully.")
        |> put_session("user_return_to", nil)
        |> redirect(to: url)
      else
        conn
        |> put_flash(:error, "You must confirm your account before you can login.")
        |> redirect(to: logged_out_url(conn))
      end
    else
      conn
      |> put_layout({Coherence.CoherenceView, "app.html"})
      |> put_view(Coherence.SessionView)
      |> put_flash(:error, "Incorrect email or password.")
      |> render(:new, [email: email])
    end
  end

  def delete(conn, _params) do
    apply(Config.auth_module, Config.delete_login, [conn])
    |> put_view(Admin1.LayoutView)
    |> redirect(to: logged_out_url(conn))
  end

  def login_callback(conn) do
    conn
    |> put_layout({Coherence.CoherenceView, "app.html"})
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
