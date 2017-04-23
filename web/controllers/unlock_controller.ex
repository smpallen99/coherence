defmodule Coherence.UnlockController do
  @moduledoc """
  Handle unlock_with_token actions.

  This controller provides the ability generate an unlock token, send
  the user an email and unlocking the account with a valid token.

  Basic locking and unlocking does not use this controller.
  """
  use Coherence.Web, :controller
  use Timex
  use Coherence.Config

  alias Coherence.ControllerHelpers, as: Helpers
  alias Coherence.{TrackableService, LockableService}

  require Logger

  @type schema :: Ecto.Schema.t
  @type conn :: Plug.Conn.t
  @type params :: Map.t

  plug Coherence.ValidateOption, :unlockable_with_token
  plug :layout_view, view: Coherence.UnlockView
  plug :redirect_logged_in when action in [:new, :create, :edit]

  @doc """
  Render the send reset link form.
  """
  @spec new(conn, params) :: conn
  def new(conn, _params) do
    user_schema = Config.user_schema
    changeset = Helpers.changeset(:unlock, user_schema, user_schema.__struct__)
    render conn, "new.html", changeset: changeset
  end

  @doc """
  Create and send the unlock token.
  """
  @spec create(conn, params) :: conn
  def create(conn, %{"unlock" => unlock_params} = params) do
    user_schema = Config.user_schema()
    email = unlock_params["email"]
    password = unlock_params["password"]

    user =
      user_schema
      |> where([u], u.email == ^email)
      |> Config.repo.one

    if user != nil and user_schema.checkpw(password, Map.get(user, Config.password_hash)) do
      case LockableService.unlock_token(user) do
        {:ok, user} ->
          if user_schema.locked?(user) do
            send_user_email :unlock, user, router_helpers().unlock_url(conn, :edit, user.unlock_token)
            conn
            |> put_flash(:info, dgettext("coherence", "Unlock Instructions sent."))
            |> redirect_to(:unlock_create, params)
          else
            conn
            |> put_flash(:error, dgettext("coherence", "Your account is not locked."))
            |> redirect_to(:unlock_create_not_locked, params)
          end
        {:error, changeset} ->
          render conn, "new.html", changeset: changeset
      end
    else
      conn
      |> put_flash(:error, dgettext("coherence", "Invalid email or password."))
      |> redirect_to(:unlock_create_invalid, params)
    end
  end

  @doc """
  Handle the unlcock link click.
  """
  @spec edit(conn, params) :: conn
  def edit(conn, params) do
    user_schema = Config.user_schema
    token = params["id"]
    unlock =
      user_schema
      |> where([u], u.unlock_token == ^token)
      |> Config.repo.one
    case unlock do
      nil ->
        conn
        |> put_flash(:error, dgettext("coherence", "Invalid unlock token."))
        |> redirect_to(:unlock_edit_invalid, params)
      user ->
        if user_schema.locked? user do
          Helpers.unlock! user
          conn
          |> TrackableService.track_unlock_token(user, user_schema.trackable_table?)
          |> put_flash(:info, dgettext("coherence", "Your account has been unlocked"))
          |> redirect_to(:unlock_edit, params)
        else
          clear_unlock_values(user, user_schema)
          conn
          |> put_flash(:error, dgettext("coherence", "Account is not locked."))
          |> redirect_to(:unlock_edit_not_locked, params)
        end
    end
  end

  @doc false
  @spec clear_unlock_values(schema, module) :: nil | :ok | String.t
  def clear_unlock_values(user, user_schema) do
    if user.unlock_token or user.locked_at do
      user_schema.changeset(user, %{unlock_token: nil, locked_at: nil})
      schema =
        :unlock
        |> Helpers.changeset(user.__struct__, user, %{unlock_token: nil, locked_at: nil})
        |> Config.repo.update
      case schema do
        {:error, changeset} ->
          lockable_failure changeset
        _ ->
          :ok
      end
    end
  end
end
