defmodule <%= web_base %>.Coherence.UnlockController do
  @moduledoc """
  Handle unlock_with_token actions.

  This controller provides the ability generate an unlock token, send
  the user an email and unlocking the account with a valid token.

  Basic locking and unlocking does not use this controller.
  """
  use CoherenceWeb, :controller
  use Timex
  use Coherence.Config

  alias Coherence.{TrackableService, LockableService, Messages}
  alias <%= base %>.Coherence.Schemas

  require Logger

  @type schema :: Ecto.Schema.t
  @type conn :: Plug.Conn.t
  @type params :: Map.t

  plug Coherence.ValidateOption, :unlockable_with_token
  plug :layout_view, view: Coherence.UnlockView, caller: __MODULE__
  plug :redirect_logged_in when action in [:new, :create, :edit]

  @doc """
  Render the send reset link form.
  """
  @spec new(conn, params) :: conn
  def new(conn, _params) do
    user_schema = Config.user_schema
    changeset = Controller.changeset(:unlock, user_schema, user_schema.__struct__)
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

    user = Schemas.get_user_by_email(email)

    if user != nil and user_schema.checkpw(password, Map.get(user, Config.password_hash)) do
      case LockableService.unlock_token(user) do
        {:ok, user} ->
          if user_schema.locked?(user) do
            conn
            |> send_unlock_email(user)
            |> respond_with(:unlock_create_success, %{params: params, user: user})
          else
            respond_with(
              conn,
              :unlock_create_error_not_locked,
              %{params: params, error: Messages.backend().your_account_is_not_locked()}
            )
          end
        {:error, changeset} ->
          respond_with(conn, :unlock_create_error, %{changeset: changeset})
      end
    else
      respond_with(
        conn,
        :unlock_create_error,
        %{params: params, error: Messages.backend().invalid_email_or_password()}
      )
    end
  end

  @doc """
  Handle the unlcock link click.
  """
  @spec edit(conn, params) :: conn
  def edit(conn, params) do
    user_schema = Config.user_schema
    token = params["id"]
    case Schemas.get_by_user unlock_token: token do
      nil ->
        respond_with(conn, :unlock_update_error, %{params: params, error: Messages.backend().invalid_unlock_token()})
      user ->
        if user_schema.locked? user do
          Controller.unlock! user
          conn
          |> TrackableService.track_unlock_token(user, user_schema.trackable_table?)
          |> respond_with(:unlock_update_success, %{params: params, info: Messages.backend().your_account_has_been_unlocked()})
        else
          clear_unlock_values(user, user_schema)
          respond_with(
            conn,
            :unlock_update_error_not_locked,
            %{error: Messages.backend().account_is_not_locked()}
          )
        end
    end
  end

  @doc false
  @spec clear_unlock_values(schema, module) :: nil | :ok | String.t
  def clear_unlock_values(user, user_schema) do
    if user.unlock_token or user.locked_at do
      schema =
        :unlock
        |> Controller.changeset(user_schema, user, %{unlock_token: nil, locked_at: nil})
        |> Schemas.update
      case schema do
        {:error, changeset} ->
          lockable_failure changeset
        _ ->
          :ok
      end
    end
  end

  defp send_unlock_email(conn, user) do
	if Config.mailer?() do
	  send_user_email :unlock, user, router_helpers().unlock_url(conn, :edit, user.unlock_token)
	  put_flash(conn, :info, Messages.backend().unlock_instructions_sent())
	else
	  put_flash(conn, :error, Messages.backend().mailer_required())
	end
  end
end
