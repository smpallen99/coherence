defmodule TestCoherenceWeb.Router do
  use Phoenix.Router
  use Coherence.Router

  def login_callback(conn) do
    Phoenix.Controller.html(conn, "Login callback rendered")
    |> Plug.Conn.halt
  end

  pipeline :browser do
    plug :accepts, ["html", "text"]
    plug :fetch_session
    plug :fetch_flash
    # plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session, db_model: TestCoherence.User
  end

  pipeline :protected do
    plug :accepts, ["html", "text"]
    plug :fetch_session
    plug :fetch_flash
    # plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session, db_model: TestCoherence.User, rememberable: true,
                                           login: &__MODULE__.login_callback/1,
                                           rememberable_callback: &Coherence.SessionController.do_rememberable_callback/5
  end

  scope "/" do
    pipe_through :browser
    coherence_routes()

    get "/dummies", TestCoherenceWeb.DummyController, :index
  end
  scope "/" do
    pipe_through :protected
    coherence_routes :protected

    get "/dummies/new", TestCoherenceWeb.DummyController, :new
  end
end

