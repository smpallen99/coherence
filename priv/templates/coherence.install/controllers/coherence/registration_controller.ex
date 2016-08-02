defmodule <%= base %>.Coherence.RegistrationController do
  @moduledoc """
  Handle account registration actions.

  Actions:

  * new - render the register form
  * create - create a new user account
  """
  use Coherence.Web, :controller
  require Logger

  plug Coherence.ValidateOption, :registerable
  plug :scrub_params, "registration" when action in [:create, :update]

  plug :layout_view

  @doc false
  def layout_view(conn, _) do
    conn
    |> put_layout({Coherence.LayoutView, "app.html"})
    |> put_view(Coherence.RegistrationView)
  end

  @doc """
  Render the new user form.
  """
  def new(conn, _params) do
    user_schema = Config.user_schema
    cs = user_schema.changeset(user_schema.__struct__)
    conn
    |> render(:new, email: "", changeset: cs)
  end

  @doc """
  Create the new user account.

  Creates the new user account. Create and send a confirmation if
  this option is enabled.
  """
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
        |> render("new.html", changeset: changeset)
    end
  end
end
