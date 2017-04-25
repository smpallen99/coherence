defmodule Coherence.ConfirmationController do
  @moduledoc """
  Handle confirmation actions.

  A single action, `edit`, is required for the confirmation module.

  """
  use Coherence.Web, :controller
  use Timex

  alias Coherence.ControllerHelpers, as: Helpers
  alias Coherence.{ConfirmableService, Messages}
  alias Ecto.DateTime

  require Logger

  plug Coherence.ValidateOption, :confirmable

  plug :layout_view, view: Coherence.ConfirmationView
  plug :redirect_logged_in when action in [:new]

  @doc """
  Handle resending a confirmation email.

  Request the user's email, reset the confirmation token and resend the email.
  """
  @spec new(Plug.Conn.t, Map.t) :: Plug.Conn.t
  def new(conn, _params) do
    user_schema = Config.user_schema
    cs = Helpers.changeset :confirmation, user_schema, user_schema.__struct__
    conn
    |> render(:new, [email: "", changeset: cs])
  end

  @doc """
  Create a new confirmation token and resend the email.
  """
  @spec create(Plug.Conn.t, Map.t) :: Plug.Conn.t
  def create(conn, %{"confirmation" => password_params} = params) do
    user_schema = Config.user_schema
    email = password_params["email"]
    user =
      user_schema
      |> where([u], u.email == ^email)
      |> Config.repo.one

    changeset = Helpers.changeset :confirmation, user_schema, user_schema.__struct__
    case user do
      nil ->
        conn
        |> put_flash(:error, Messages.backend().could_not_find_that_email_address())
        |> render("new.html", changeset: changeset)
      user ->
        if user_schema.confirmed?(user) do
          conn
          |> put_flash(:error, Messages.backend().account_already_confirmed())
          |> render(:new, [email: "", changeset: changeset])
        else
          conn
          |> send_confirmation(user, user_schema)
          |> redirect_to(:confirmation_create, params)
        end
    end
  end

  @doc """
  Handle the user's click on the confirm link in the confirmation email.

  Validate that the confirmation token has not expired and sets `confirmation_sent_at`
  field to nil, marking the user as confirmed.
  """
  @spec edit(Plug.Conn.t, Map.t) :: Plug.Conn.t
  def edit(conn, params) do
    user_schema = Config.user_schema
    token = params["id"]
    user =
      user_schema
      |> where([u], u.confirmation_token == ^token)
      |> Config.repo.one

    case user do
      nil ->
        changeset = Helpers.changeset :confirmation, user_schema, user_schema.__struct__
        conn
        |> put_flash(:error, Messages.backend().invalid_confirmation_token())
        |> redirect_to(:confirmation_edit_invalid, params)
      user ->
        if ConfirmableService.expired? user do
          conn
          |> put_flash(:error, Messages.backend().confirmation_token_expired())
          |> redirect_to(:confirmation_edit_expired, params)
        else
          changeset = Helpers.changeset(:confirmation, user_schema, user, %{
            confirmation_token: nil,
            confirmed_at: DateTime.utc,
            })
          case Config.repo.update(changeset) do
            {:ok, _user} ->
              conn
              |> put_flash(:info, Messages.backend().user_account_confirmed_successfully())
              |> redirect_to(:confirmation_edit, params)
            {:error, _changeset} ->
              conn
              |> put_flash(:error, Messages.backend().problem_confirming_user_account())
              |> redirect_to(:confirmation_edit_error, params)
          end
        end
    end
  end
end
