defmodule Coherence.UnlockController do
  @moduledoc """
  Handle unlock_with_token actions.

  This controller provides the ability generate an unlock token, send
  the user an email and unlocking the account with a valid token.

  Basic locking and unlocking does not use this controller.
  """
  use Coherence.Web, :controller
  require Logger
  use Timex
  use Coherence.Config
  alias Coherence.ControllerHelpers, as: Helpers

  plug Coherence.ValidateOption, :unlockable_with_token
  plug :layout_view
  plug :redirect_logged_in when action in [:new, :create, :edit]

  @doc false
  def layout_view(conn, _) do
    conn
    |> put_layout({Coherence.LayoutView, "app.html"})
    |> put_view(Coherence.UnlockView)
  end

  @doc """
  Render the send reset link form.
  """
  def new(conn, _params) do
    user_schema = Config.user_schema
    changeset = Helpers.changeset(:unlock, user_schema, user_schema.__struct__)
    render conn, "new.html", changeset: changeset
  end

  @doc """
  Create and send the unlock token.
  """
  def create(conn, %{"unlock" => unlock_params} = params) do
    user_schema = Config.user_schema
    token = random_string 48
    url = router_helpers.unlock_url(conn, :edit, token)
    email = unlock_params["email"]
    password = unlock_params["password"]

    user = where(user_schema, [u], u.email == ^email)
    |> Config.repo.one

    if user != nil and user_schema.checkpw(password, Map.get(user, Config.password_hash)) do
      Helpers.changeset(:unlock, user.__struct__, user, %{unlock_token: token})
      |> Config.repo.update
      |> case do
        {:ok, _} ->
          if user_schema.locked?(user) do
            send_user_email :unlock, user, url
            conn
            |> put_flash(:info, "Unlock Instructions sent.")
            |> redirect_to(:unlock_create, params)
          else
            conn
            |> put_flash(:error, "Your account is not locked.")
            |> redirect_to(:unlock_create_not_locked, params)
          end
        {:error, changeset} ->
          render conn, "new.html", changeset: changeset
      end
    else
      conn
      |> put_flash(:error, "Invalid email or password.")
      |> redirect_to(:unlock_create_invalid, params)
    end
  end

  @doc """
  Handle the unlcock link click.
  """
  def edit(conn, params) do
    user_schema = Config.user_schema
    token = params["id"]
    where(user_schema, [u], u.unlock_token == ^token)
    |> Config.repo.one
    |> case do
      nil ->
        conn
        |> put_flash(:error, "Invalid unlock token.")
        |> redirect_to(:unlock_edit_invalid, params)
      user ->
        if user_schema.locked? user do
          user_schema.unlock! user
          conn
          |> put_flash(:info, "Your account has been unlocked")
          |> redirect_to(:unlock_edit, params)
        else
          clear_unlock_values(user, user_schema)
          conn
          |> put_flash(:error, "Account is not locked.")
          |> redirect_to(:unlock_edit_not_locked, params)
        end
    end
  end

  @lockable_failure "Failed to update lockable attributes "

  @doc false
  def clear_unlock_values(user, user_schema) do
    if user.unlock_token or user.locked_at do
      user_schema.changeset(user, %{unlock_token: nil, locked_at: nil})
      Helpers.changeset(:unlock, user.__struct__, user, %{unlock_token: nil, locked_at: nil})
      |> Config.repo.update
      |> case do
        {:error, changeset} ->
          lockable_failure changeset
        _ -> :ok
      end
    end
  end
end
