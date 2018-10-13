defmodule Coherence.ConfirmationControllerBase do
  @moduledoc """
  Handle confirmation actions.

  A single action, `edit`, is required for the confirmation module.

  """
  defmacro __using__(opts) do
    quote location: :keep do
      use Timex

      alias Coherence.{ConfirmableService, Messages, Controller, Schema}
      alias Coherence.Schemas

      require Coherence.Config, as: Config
      require Logger

      @schemas unquote(opts)[:schemas] || raise("Schemas option required")

      def schema(which), do: Coherence.Schemas.schema(which)

      @doc """
      Handle resending a confirmation email.

      Request the user's email, reset the confirmation token and resend the email.
      """
      @spec new(Plug.Conn.t(), Map.t()) :: Plug.Conn.t()
      def new(conn, _params) do
        user_schema = Config.user_schema()
        cs = Controller.changeset(:confirmation, user_schema, user_schema.__struct__)

        conn
        |> render(:new, email: "", changeset: cs)
      end

      @doc """
      Create a new confirmation token and resend the email.
      """
      @spec create(Plug.Conn.t(), Map.t()) :: Plug.Conn.t()
      def create(conn, %{"confirmation" => password_params} = params) do
        user_schema = Config.user_schema()
        email = password_params["email"]
        user = @schemas.get_user_by_email(email)

        changeset = Controller.changeset(:confirmation, user_schema, user_schema.__struct__)

        case user do
          nil ->
            conn
            |> respond_with(
              :confirmation_create_error,
              %{
                changeset: changeset,
                error: Messages.backend().could_not_find_that_email_address()
              }
            )

          user ->
            if user_schema.confirmed?(user) do
              conn
              |> respond_with(
                :confirmation_create_error,
                %{
                  changeset: changeset,
                  email: "",
                  error: Messages.backend().account_already_confirmed()
                }
              )
            else
              conn
              |> send_confirmation(user, user_schema)
              |> respond_with(:confirmation_create_success, %{params: params})
            end
        end
      end

      @doc """
      Handle the user's click on the confirm link in the confirmation email.

      Validate that the confirmation token has not expired and sets `confirmation_sent_at`
      field to nil, marking the user as confirmed.
      """
      @spec edit(Plug.Conn.t(), Map.t()) :: Plug.Conn.t()
      def edit(conn, params) do
        user_schema = Config.user_schema()
        token = params["id"]

        user = @schemas.get_by_user(confirmation_token: token)

        case user do
          nil ->
            changeset = Controller.changeset(:confirmation, user_schema, user_schema.__struct__)

            conn
            |> respond_with(
              :confirmation_update_invalid,
              %{
                params: params,
                error: Messages.backend().invalid_confirmation_token()
              }
            )

          user ->
            if ConfirmableService.expired?(user) do
              conn
              |> respond_with(
                :confirmation_update_expired,
                %{
                  params: params,
                  error: Messages.backend().confirmation_token_expired()
                }
              )
            else
              attrs =
                if Config.get(:confirm_email_updates) do
                  %{
                    email: user.unconfirmed_email,
                    unconfirmed_email: nil
                  }
                else
                  %{}
                end
                |> Map.merge(%{
                  confirmation_token: nil,
                  confirmed_at: NaiveDateTime.utc_now()
                })

              changeset = Controller.changeset(:confirmation, user_schema, user, attrs)

              case Config.repo().update(changeset) do
                {:ok, _user} ->
                  conn
                  |> respond_with(
                    :confirmation_update_success,
                    %{
                      params: params,
                      info: Messages.backend().user_account_confirmed_successfully()
                    }
                  )

                {:error, _changeset} ->
                  conn
                  |> respond_with(
                    :confirmation_update_error,
                    %{
                      params: params,
                      error: Messages.backend().problem_confirming_user_account()
                    }
                  )
              end
            end
        end
      end

      defoverridable(new: 2, create: 2, edit: 2)
    end
  end
end
