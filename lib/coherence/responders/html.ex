defmodule Responders.Html do

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Coherence.Responders

      import Phoenix.Controller, only: [redirect: 2, put_flash: 3, render: 3]
      import Coherence.Controller
      import Plug.Conn, only: [put_status: 2, halt: 1]

      def session_create_error(conn, opts \\ %{})
      def session_create_error(conn, %{new_bindings: new_bindings, error: error}) do
        conn
        |> put_flash(:error, error)
        |> put_status(406)
        |> render(:new, new_bindings)
      end
      def session_create_error(conn, %{new_bindings: new_bindings}) do
        conn
        |> put_status(401)
        |> render(:new, new_bindings)
      end

      def session_create_success(conn, opts \\ %{})
      def session_create_success(conn, %{notice: notice, params: params}) do
        conn
        |> put_flash(:notice, notice)
        |> redirect_to(:session_create, params)
      end

      def session_create_error_locked(conn, opts \\ %{})
      def session_create_error_locked(conn, %{error: error, params: params}) do
        conn
        |> put_flash(:error, error)
        |> put_status(423)
        |> render(:new, params)
      end

      def session_delete_success(conn, opts \\ %{})
      def session_delete_success(conn, %{params: params}) do
        conn
        |> redirect_to(:session_delete, params)
      end

      def session_already_logged_in(conn, opts \\ %{})
      def session_already_logged_in(conn, %{info: info}) do
        conn
        |> put_flash(:info, info)
        |> redirect(to: logged_in_url(conn))
        |> halt
      end

      def registration_create_success(conn, opts \\ %{})
      def registration_create_success(conn, %{params: params}) do
        conn
        |> redirect_to(:session_create, params)
      end

      def registration_create_error(conn, opts \\ %{})
      def registration_create_error(conn, %{changeset: changeset}) do
        conn
        |> render(:new, changeset: changeset)
      end

      def registration_update_error(conn, opts \\ %{})
      def registration_update_error(conn, %{changeset: changeset, user: user}) do
        conn
        |> render(:edit, changeset: changeset, user: user)
      end

      def registration_update_success(conn, opts \\ %{})
      def registration_update_success(conn, %{params: params, user: user, info: info}) do
        conn
        |> put_flash(:info, info)
        |> redirect_to(:registration_update, params, user)
      end

      def registration_delete_success(conn, opts \\ %{})
      def registration_delete_success(conn, %{params: params}) do
        conn
        |> redirect_to(:registration_delete, params)
      end

      def unlock_create_success(conn, opts \\ %{params: %{}, user: nil})
      def unlock_create_success(conn, %{params: params}) do
        conn
        |> redirect_to(:unlock_create, params)
      end

      def unlock_create_error(conn, opts \\ %{})
      def unlock_create_error(conn, %{params: params, error: error}) do
        conn
        |> put_flash(:error, error)
        |> redirect_to(:unlock_create_invalid, params)
      end
      def unlock_create_error(conn, %{changeset: changeset}) do
        render conn, :new, changeset: changeset
      end

      def unlock_create_error_not_locked(conn, opts \\ %{})
      def unlock_create_error_not_locked(conn, %{params: params, error: error}) do
        conn
        |> put_flash(:error, error)
        |> redirect_to(:unlock_create_not_locked, params)
      end

      def unlock_update_success(conn, opts \\ %{})
      def unlock_update_success(conn, %{params: params, info: info}) do
        conn
        |> put_flash(:info, info)
        |> redirect_to(:unlock_edit, params)
      end

      def unlock_update_error(conn, opts \\ %{})
      def unlock_update_error(conn, %{params: params, error: error}) do
        conn
        |> put_flash(:error, error)
        |> redirect_to(:unlock_edit_invalid, params)
      end

      def unlock_update_error_not_locked(conn, opts \\ %{})
      def unlock_update_error_not_locked(conn, %{params: params, error: error}) do
        conn
        |> put_flash(:error, error)
        |> redirect_to(:unlock_edit_not_locked, params)
      end

      def confirmation_create_error(conn, opts \\ %{})
      def confirmation_create_error(conn, %{changeset: changeset, email: email, error: error}) do
        conn
        |> put_flash(:error, error)
        |> render(:new, [email: email, changeset: changeset])
      end
      def confirmation_create_error(conn, %{changeset: changeset, error: error}) do
        conn
        |> put_flash(:error, error)
        |> render(:new, changeset: changeset)
      end
      def confirmation_create_error(conn, %{changeset: changeset}) do
        conn
        |> render(:new, changeset: changeset)
      end

      def confirmation_create_success(conn, opts \\ %{})
      def confirmation_create_success(conn, %{params: params}) do
        conn
        |> redirect_to(:confirmation_create, params)
      end

      def confirmation_update_invalid(conn, opts \\ %{})
      def confirmation_update_invalid(conn, %{params: params, error: error}) do
        conn
        |> put_flash(:error, error)
        |> redirect_to(:confirmation_edit_invalid, params)
      end

      def confirmation_update_expired(conn, opts \\ %{})
      def confirmation_update_expired(conn, %{params: params, error: error}) do
        conn
        |> put_flash(:error, error)
        |> redirect_to(:confirmation_edit_expired, params)
      end

      def confirmation_update_error(conn, opts \\ %{})
      def confirmation_update_error(conn, %{params: params, error: error}) do
        conn
        |> put_flash(:error, error)
        |> redirect_to(:confirmation_edit_error, params)
      end

      def confirmation_update_success(conn, opts \\ %{})
      def confirmation_update_success(conn, %{params: params, info: info}) do
        conn
        |> put_flash(:info, info)
        |> redirect_to(:confirmation_edit, params)
      end

      def password_create_success(conn, opts \\ %{})
      def password_create_success(conn, %{params: params, info: info}) do
        conn
        |> put_flash(:info, info)
        |> redirect_to(:password_create, params: params)
      end
      def password_create_success(conn, %{params: params, error: error}) do
        conn
        |> put_flash(:error, error)
        |> redirect_to(:password_create, params: params)
      end

      def password_create_error(conn, opts \\ %{})
      def password_create_error(conn, %{changeset: changeset, error: error}) do
        conn
        |> put_flash(:error, error)
        |> render(:new, changeset: changeset)
      end

      def password_update_error(conn, opts \\ %{})
      def password_update_error(conn, %{error: error}) do
        conn
        |> put_flash(:error, error)
        |> redirect(to: logged_out_url(conn))
      end
      def password_update_error(conn, %{changeset: changeset}) do
        conn
        |> render("edit.html", changeset: changeset)
      end

      def password_update_success(conn, %{params: params, info: info}) do
        conn
        |> put_flash(:info, info)
        |> redirect_to(:password_update, params)
      end

      def invitation_create_success(conn, opts \\ %{})
      def invitation_create_success(conn, %{params: params, info: info}) do
        conn
        |> put_flash(:info, info)
        |> redirect_to(:invitation_create, params)
      end

      def invitation_create_error(conn, opts \\ %{})
      def invitation_create_error(conn, %{changeset: changeset}) do
        conn
        |> render(:new, changeset: changeset)
      end

      def invitation_resend_error(conn, opts \\ %{})
      def invitation_resend_error(conn, %{error: error, params: params}) do
        conn
        |> put_flash(:error, error)
        |> redirect_to(:invitation_resend, params)
      end

      def invitation_resend_success(conn, opts \\ %{})
      def invitation_resend_success(conn, %{info: info, params: params}) do
        conn
        |> put_flash(:info, info)
        |> redirect_to(:invitation_resend, params)
      end

      def invitation_create_user_error(conn, opts \\ %{})
      def invitation_create_user_error(conn, %{error: error}) do
        conn
        |> put_flash(:error, error)
        |> redirect(to: logged_out_url(conn))
      end
      def invitation_create_user_error(conn, %{changeset: changeset, token: token}) do
        conn
        |> render(:edit, changeset: changeset, token: token)
      end

      def invitation_create_user_success(conn, opts \\ %{})
      def invitation_create_user_success(conn, %{}) do
        conn
        |> redirect(to: logged_out_url(conn))
      end

      defoverridable [
        session_create_success: 2,
        session_create_error: 2,
        session_create_error_locked: 2,
        session_delete_success: 2,
        session_already_logged_in: 2,

        registration_create_success: 2,
        registration_create_error: 2,
        registration_update_success: 2,
        registration_update_error: 2,
        registration_delete_success: 2,

        unlock_create_success: 2,
        unlock_create_error: 2,
        unlock_create_error_not_locked: 2,
        unlock_update_success: 2,
        unlock_update_error: 2,
        unlock_update_error_not_locked: 2,

        confirmation_create_success: 2,
        confirmation_create_error: 2,
        confirmation_update_error: 2,
        confirmation_update_success: 2,

        password_create_success: 2,
        password_create_error: 2,
        password_update_success: 2,
        password_update_error: 2,

        invitation_create_success: 2,
        invitation_create_error: 2,
        invitation_resend_success: 2,
        invitation_resend_error: 2,
        invitation_create_user_success: 2,
        invitation_create_user_error: 2
      ]
    end
  end

end
