defmodule Coherence.RegistrationController do
  @moduledoc """
  Handle account registration actions.

  Actions:

  * new - render the register form
  * create - create a new user account
  * edit - edit the user account
  * update - update the user account
  * delete - delete the user account
  """
  use Coherence.Web, :controller
  require Logger
  alias Coherence.ControllerHelpers, as: Helpers

  plug Coherence.ValidateOption, :registerable
  plug :scrub_params, "registration" when action in [:create, :update]

  plug :layout_view
  plug :redirect_logged_in when action in [:new, :create]

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
    cs = Helpers.changeset(:registration, user_schema, user_schema.__struct__)
    conn
    |> render(:new, email: "", changeset: cs)
  end

  @doc """
  Create the new user account.

  Creates the new user account. Create and send a confirmation if
  this option is enabled.
  """
  def create(conn, %{"registration" => registration_params} = params) do
    user_schema = Config.user_schema
    cs = Helpers.changeset(:registration, user_schema, user_schema.__struct__, registration_params)
    case Config.repo.insert(cs) do
      {:ok, user} ->
        apply(Config.auth_module, Config.create_login, [conn, user, [id_key: Config.schema_key]])
        |> Helpers.track_login(user, user_schema.trackable?)
        |> send_confirmation(user, user_schema)
        |> redirect_to(:session_create, params)
      {:error, changeset} ->
        conn
        |> render("new.html", changeset: changeset)
    end
  end

  @doc """
  Show the registration page.
  """
  def show(conn, _) do
    user = Coherence.current_user(conn)
    render(conn, "show.html", user: user)
  end

  @doc """
  Edit the registration.
  """
  def edit(conn, _) do
    user = Coherence.current_user(conn)
    changeset = Helpers.changeset(:registration, user.__struct__, user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  @doc """
  Update the registration.
  """
  def update(conn, %{"id" => _id, "registration" => user_params} = params) do
    user_schema = Config.user_schema
    user = Coherence.current_user(conn)
    changeset = Helpers.changeset(:registration, user_schema, user, user_params)
    case Config.repo.update(changeset) do
      {:ok, user} ->
        apply(Config.auth_module, Config.update_login, [conn, user, [id_key: Config.schema_key]])
        |> put_flash(:info, "Account updated successfully.")
        |> redirect_to(:registration_update, params, user)
      {:error, changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  @doc """
  Delete a registration.
  """
  def delete(conn, params) do
    user = Coherence.current_user(conn)
    conn = Coherence.SessionController.delete(conn)
    Config.repo.delete! user
    redirect_to(conn, :registration_delete, params)
  end
end
