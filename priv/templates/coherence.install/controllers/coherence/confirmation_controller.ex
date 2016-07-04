defmodule <%= base %>.Coherence.ConfirmationController do
  @moduledoc """
  Handle confirmation actions.

  A single action, `edit`, is required for the confirmation module.

  """
  use Coherence.Web, :controller
  require Logger
  use Timex

  plug Coherence.ValidateOption, :confirmable

  @doc """
  Handle the user's click on the confirm link in the confirmation email.

  Validate that the confirmation token has not expired and sets `confirmation_send_at`
  field to nil, marking the user as confirmed.

  TODO: Need to support a resend confirmation email.

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
        if expired? user.confirmation_send_at, days: Config.confirmation_token_expire_days do
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
              |> put_flash(:info, "User confirmed successfully.")
              |> redirect(to: logged_out_url(conn))
            {:error, _changeset} ->
              conn
              |> put_flash(:error, "Problem confirming user. Please contact the system administrator.")
              |> redirect(to: logged_out_url(conn))
          end
        end
    end
  end

end
