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
  use CoherenceWeb, :controller

  alias Coherence.Messages
  alias Coherence.Schemas

  require Logger

  @type schema :: Ecto.Schema.t
  @type conn :: Plug.Conn.t
  @type params :: Map.t

  @dialyzer [
    {:nowarn_function, update: 2},
  ]

  plug Coherence.RequireLogin when action in ~w(show edit update delete)a
  plug Coherence.ValidateOption, :registerable
  plug :scrub_params, "registration" when action in [:create, :update]

  plug :layout_view, view: Coherence.RegistrationView, caller: __MODULE__
  plug :redirect_logged_in when action in [:new, :create]

  @doc """
  Render the new user form.
  """
  @spec new(conn, params) :: conn
  def new(conn, _params) do
    user_schema = Config.user_schema
    changeset = Controller.changeset(:registration, user_schema, user_schema.__struct__)
    render(conn, :new, email: "", changeset: changeset)
  end

  @doc """
  Create the new user account.

  Creates the new user account. Create and send a confirmation if
  this option is enabled.
  """
  @spec create(conn, params) :: conn
  def create(conn, %{"registration" => registration_params} = params) do
    user_schema = Config.user_schema
    :registration
    |> Controller.changeset(user_schema, user_schema.__struct__, registration_params)
    |> Schemas.create
    |> case do
      {:ok, user} ->
        conn
        |> send_confirmation(user, user_schema)
        |> redirect_or_login(user, params, Config.allow_unconfirmed_access_for)
      {:error, changeset} ->
        respond_with(conn, :registration_create_error, %{changeset: changeset})
    end
  end

  defp redirect_or_login(conn, user, params, 0) do
    respond_with(conn, :registration_create_success, %{params: params, user: user})
  end
  defp redirect_or_login(conn, user, params, _) do
    conn
    |> Controller.login_user(user, params)
    |> respond_with(:session_create_success, %{params: params, user: user})
  end

  @doc """
  Show the registration page.
  """
  @spec show(conn, any) :: conn
  def show(conn, _) do
    user = Coherence.current_user(conn)
    render(conn, "show.html", user: user)
  end

  @doc """
  Edit the registration.
  """
  @spec edit(conn, any) :: conn
  def edit(conn, _) do
    user = Coherence.current_user(conn)
    changeset = Controller.changeset(:registration, user.__struct__, user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  @doc """
  Update the registration.
  """
  @spec update(conn, params) :: conn
  def update(conn, %{"registration" => user_params} = params) do
    user_schema = Config.user_schema
    user = Coherence.current_user(conn)
    :registration
    |> Controller.changeset(user_schema, user, user_params)
    |> Schemas.update
    |> case do
      {:ok, user} ->
        Config.auth_module
        |> apply(Config.update_login, [conn, user, [id_key: Config.schema_key]])
        |> respond_with(
          :registration_update_success,
          %{
            user: user,
            params: params,
            info: Messages.backend().account_updated_successfully()
          }
        )
      {:error, changeset} ->
        respond_with(conn, :registration_update_error, %{user: user, changeset: changeset})
    end
  end

  @doc """
  Delete a registration.
  """
  @spec update(conn, params) :: conn
  def delete(conn, params) do
    user = Coherence.current_user(conn)
    conn = Controller.logout_user(conn)
    Schemas.delete! user
    respond_with(conn, :registration_delete_success, %{params: params})
  end
end
