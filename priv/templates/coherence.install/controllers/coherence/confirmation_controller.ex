defmodule <%= base %>.Coherence.ConfirmationController do
  @moduledoc """
  Handle confirmation actions.

  A single action, `edit`, is required for the confirmation module.

  """
  use Coherence.Web, :controller
  require Logger
  use Timex

  plug Coherence.ValidateOption, :confirmable

  plug :layout_view
  plug :redirect_logged_in when action in [:new]

  @doc false
  def layout_view(conn, _) do
    conn
    |> put_layout({Coherence.LayoutView, "app.html"})
    |> put_view(Coherence.ConfirmationView)
  end

  @doc """
  Handle resending a confirmation email.

  Request the user's email, reset the confirmation token and resend the email.
  """
  def new(conn, _params) do
    user_schema = Config.user_schema
    cs = user_schema.changeset(user_schema.__struct__)
    conn
    |> render(:new, [email: "", changeset: cs])
  end

  @doc """
  Create a new confirmation token and resend the email.
  """
  def create(conn, %{"confirmation" => password_params}) do
    user_schema = Config.user_schema
    email = password_params["email"]
    user = where(user_schema, [u], u.email == ^email)
    |> Config.repo.one

    changeset = user_schema.changeset(user_schema.__struct__)
    case user do
      nil ->
        conn
        |> put_flash(:error, "Could not find that email address")
        |> render("new.html", changeset: changeset)
      user ->
        if user_schema.confirmed?(user) do
          conn
          |> put_flash(:error, "Account already confirmed.")
          |> render(:new, [email: "", changeset: changeset])
        else
          conn
          |> send_confirmation(user, user_schema)
          |> redirect(to: logged_out_url(conn))
        end
    end
  end

  @doc """
  Handle the user's click on the confirm link in the confirmation email.

  Validate that the confirmation token has not expired and sets `confirmation_sent_at`
  field to nil, marking the user as confirmed.
  """
  def edit(conn, params) do
    user_schema = Config.user_schema
    token = params["id"]
    user = where(user_schema, [u], u.confirmation_token == ^token)
    |> Config.repo.one
    case user do
      nil ->
        changeset = user_schema.changeset(user_schema.__struct__)
        conn
        |> put_flash(:error, "Invalid confirmation token.")
        |> redirect(to: logged_out_url(conn))
      user ->
        if expired? user.confirmation_sent_at, days: Config.confirmation_token_expire_days do
          conn
          |> put_flash(:error, "Confirmation token expired.")
          |> redirect(to: logged_out_url(conn))
        else
          changeset = user_schema.changeset(user, %{
            confirmation_token: nil,
            confirmed_at: Ecto.DateTime.utc,
            })
          case Config.repo.update(changeset) do
            {:ok, _user} ->
              conn
              |> put_flash(:info, "User account confirmed successfully.")
              |> redirect(to: logged_out_url(conn))
            {:error, _changeset} ->
              conn
              |> put_flash(:error, "Problem confirming user account. Please contact the system administrator.")
              |> redirect(to: logged_out_url(conn))
          end
        end
    end
  end

end
