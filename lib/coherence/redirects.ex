defmodule Redirects do
  @moduledoc """
  Define controller action redirection behaviour.

  Defines the default redirect functions for each of the controller
  actions that perform redirects. By using this Module you get the following
  functions:

  * session_create/2
  * session_delete/2
  * password_create/2
  * password_update/2,
  * unlock_create_not_locked/2
  * unlock_create_invalid/2
  * unlock_create/2
  * unlock_edit_not_locked/2
  * unlock_edit/2
  * unlock_edit_invalid/2
  * registration_create/2
  * registration_delete/2
  * invitation_create/2
  * invitation_resend/2
  * confirmation_create/2
  * confirmation_edit_invalid/2
  * confirmation_edit_expired/2
  * confirmation_edit/2
  * confirmation_edit_error/2

  You can override any of the functions to customize the redirect path. Each
  function is passed the `conn` and `params` arguments from the controller.

  ## Examples

      use Redirects
      import MyProject.Router.Helpers

      # override the log out action back to the log in page
      def session_delete(conn, _), do: redirect(conn, to: session_path(conn, :new))

      # redirect the user to the login page after registering
      def registration_create(conn, _), do: redirect(conn, to: session_path(conn, :new))

      # disable the user_return_to feature on login
      def session_create(conn, _), do: redirect(conn, to: landing_path(conn, :index))

  """
  @callback session_create(conn :: term, params :: term) :: term
  @callback session_delete(conn :: term, params :: term) :: term

  @callback password_create(conn :: term, params :: term) :: term
  @callback password_update(conn :: term, params :: term) :: term

  @callback unlock_create(conn :: term, params :: term) :: term
  @callback unlock_create_not_locked(conn :: term, params :: term) :: term
  @callback unlock_create_invalid(conn :: term, params :: term) :: term

  @callback unlock_edit(conn :: term, params :: term) :: term
  @callback unlock_edit_not_locked(conn :: term, params :: term) :: term
  @callback unlock_edit_invalid(conn :: term, params :: term) :: term

  @callback registration_create(conn :: term, params :: term) :: term
  @callback registration_update(conn :: term, params :: term, user :: term) :: term
  @callback registration_delete(conn :: term, params :: term) :: term

  @callback invitation_create(conn :: term, params :: term) :: term
  @callback invitation_resend(conn :: term, params :: term) :: term

  @callback confirmation_create(conn :: term, params :: term) :: term
  @callback confirmation_edit_invalid(conn :: term, params :: term) :: term
  @callback confirmation_edit_expired(conn :: term, params :: term) :: term
  @callback confirmation_edit(conn :: term, params :: term) :: term
  @callback confirmation_edit_error(conn :: term, params :: term) :: term

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Redirects

      import Phoenix.Controller, only: [redirect: 2]
      import Coherence.Controller
      import Plug.Conn, only: [get_session: 2, put_session: 3]

      @doc false
      def session_delete(conn, _), do: redirect(conn, to: logged_out_url(conn))

      @doc false
      def session_create(conn, _) do
        url = case get_session(conn, "user_return_to") do
          nil -> "/"
          value -> value
        end
        conn
        |> put_session("user_return_to", nil)
        |> redirect(to: url)
      end

      @doc false
      def password_create(conn, _), do: redirect(conn, to: logged_out_url(conn))
      @doc false
      def password_update(conn, _), do: redirect(conn, to: logged_out_url(conn))

      @doc false
      def unlock_create(conn, _), do: redirect(conn, to: logged_out_url(conn))
      @doc false
      def unlock_create_not_locked(conn, _), do: redirect(conn, to: logged_out_url(conn))
      @doc false
      def unlock_create_invalid(conn, _), do: redirect(conn, to: logged_out_url(conn))

      @doc false
      def unlock_edit(conn, _), do: redirect(conn, to: logged_out_url(conn))
      @doc false
      def unlock_edit_not_locked(conn, _), do: redirect(conn, to: logged_out_url(conn))
      @doc false
      def unlock_edit_invalid(conn, _), do: redirect(conn, to: logged_out_url(conn))

      @doc false
      def registration_create(conn, _), do: redirect(conn, to: logged_out_url(conn))
      @doc false
      def registration_update(conn, _, user) do
        path =
          Coherence.Config.router()
          |> Module.concat(Helpers)
          |> apply(:registration_path, [conn, :show])
        redirect(conn, to: path)
      end
      @doc false
      def registration_delete(conn, _), do: redirect(conn, to: logged_out_url(conn))

      @doc false
      def invitation_create(conn, _), do: redirect(conn, to: logged_out_url(conn))
      @doc false
      def invitation_resend(conn, _), do: redirect(conn, to: logged_out_url(conn))

      @doc false
      def confirmation_create(conn, _), do: redirect(conn, to: logged_out_url(conn))
      @doc false
      def confirmation_edit_invalid(conn, _), do: redirect(conn, to: logged_out_url(conn))
      @doc false
      def confirmation_edit_expired(conn, _), do: redirect(conn, to: logged_out_url(conn))
      @doc false
      def confirmation_edit(conn, _), do: redirect(conn, to: logged_out_url(conn))
      @doc false
      def confirmation_edit_error(conn, _), do: redirect(conn, to: logged_out_url(conn))

      defoverridable [
        session_create: 2, session_delete: 2, password_create: 2, password_update: 2,
        unlock_create_not_locked: 2, unlock_create_invalid: 2, unlock_create: 2,
        unlock_edit_not_locked: 2, unlock_edit: 2, unlock_edit_invalid: 2,
        registration_create: 2, registration_update: 3, registration_delete: 2,
        invitation_create: 2, invitation_resend: 2,
        confirmation_create: 2, confirmation_edit_invalid: 2, confirmation_edit_expired: 2,
        confirmation_edit: 2, confirmation_edit_error: 2
      ]
    end
  end

end
