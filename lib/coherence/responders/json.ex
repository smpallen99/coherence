defmodule Responders.Json do

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Coherence.Responders

      import Phoenix.Controller, only: [render: 2, render: 3, render: 4]
      import Coherence.Controller
      import Plug.Conn, only: [put_status: 2, send_resp: 3, halt: 1]

      def session_create_success(conn, opts \\ %{})
      def session_create_success(conn, _opts) do
        conn
        |> put_status(201)
        |> render(:session, user: conn.assigns.current_user)
      end

      def session_create_error(conn, opts \\ %{})
      def session_create_error(conn, %{error: error}) do
        conn
        |> put_status(406)
        |> render(:error, error: error)
      end
      def session_create_error(conn, _opts) do
        conn
        |> put_status(401)
        |> render(:error)
      end

      def session_create_error_locked(conn, opts \\ %{})
      def session_create_error_locked(conn, %{error: error}) do
        conn
        |> put_status(423)
        |> render(:error, error: error)
      end

      def session_delete_success(conn, opts \\ %{})
      def session_delete_success(conn, _) do
        conn
        |> send_resp(204, "")
      end

      def session_already_logged_in(conn, opts \\ %{})
      def session_already_logged_in(conn, %{info: info}) do
        conn
        |> put_status(409)
        |> render(:error, error: info)
        |> halt
      end

      def registration_create_success(conn, opts \\ %{})
      def registration_create_success(conn, %{user: user}) do
        conn
        |> render(:registration, user: user)
      end

      def registration_create_error(conn, opts \\ %{})
      def registration_create_error(conn, %{changeset: changeset}) do
        conn
        |> put_status(422)
        |> render(:error, changeset: changeset)
      end

      def registration_update_error(conn, opts \\ %{})
      def registration_update_error(conn, %{changeset: changeset}) do
        conn
        |> put_status(422)
        |> render(:error, changeset: changeset)
      end

      def registration_update_success(conn, opts \\ %{})
      def registration_update_success(conn, %{user: user, info: info}) do
        conn
        |> render(:registration, user: user, info: info)
      end

      def registration_delete_success(conn, opts \\ %{})
      def registration_delete_success(conn, %{params: params}) do
        conn
        |> send_resp(204, "")
      end

      def unlock_create_success(conn, %{user: user}) do
        conn
        |> put_status(201)
        |> render(:unlock, user: user)
      end

      def unlock_create_error(conn, %{error: error}) do
        conn
        |> put_status(422)
        |> render(:error, error: error)
      end
      def unlock_create_error(conn, %{changeset: changeset}) do
        conn
        |> put_status(422)
        |> render(:error, changeset: changeset)
      end

      def unlock_create_error_not_locked(conn, %{error: error}) do
        conn
        |> put_status(422)
        |> render(:error, error: error)
      end

      def unlock_update_success(conn, opts \\ %{})
      def unlock_update_success(conn, %{params: _params, info: info}) do
        conn
        |> put_status(200)
        |> render(:unlock, info: info)
      end

      def unlock_update_error(conn, opts \\ %{})
      def unlock_update_error(conn, %{params: _params, error: error}) do
        conn
        |> put_status(422)
        |> render(:error, error: error)
      end

      def unlock_update_error_not_locked(conn, opts \\ %{})
      def unlock_update_error_not_locked(conn, %{params: _params, error: error}) do
        conn
        |> put_status(422)
        |> render(:error, error: error)
      end

      def confirmation_create_success(conn, %{params: params}) do
        conn
        |> send_resp(201, "")
      end

      def confirmation_create_error(conn, opts) do
        conn
        |> put_status(422)
        |> render(:error, opts)
      end

      def confirmation_update_success(conn, opts \\ %{})
      def confirmation_update_success(conn, %{info: info}) do
        conn
        |> put_status(200)
        |> render(:confirmation, info: info)
      end

      def confirmation_update_invalid(conn, opts \\ %{})
      def confirmation_update_invalid(conn, %{error: error}) do
        conn
        |> put_status(422)
        |> render(:error, error: error)
      end

      def confirmation_update_expired(conn, opts \\ %{})
      def confirmation_update_expired(conn, %{error: error}) do
        conn
        |> put_status(422)
        |> render(:error, error: error)
      end

      def confirmation_update_error(conn, opts \\ %{})
      def confirmation_update_error(conn, %{error: error}) do
        conn
        |> put_status(422)
        |> render(:error, error: error)
      end

      def password_create_success(conn, opts \\ %{})
      def password_create_success(conn, %{params: params, info: info}) do
        conn
        |> put_status(201)
        |> render(:password, info: info)
      end
      def password_create_success(conn, %{params: params, error: error}) do
        conn
        |> put_status(422)
        |> render(:error, error: error)
      end

      def password_create_error(conn, opts \\ %{})
      def password_create_error(conn, %{changeset: changeset, error: error}) do
        conn
        |> put_status(422)
        |> render(:error, changeset: changeset, error: error)
      end

      def password_update_error(conn, opts \\ %{})
      def password_update_error(conn, %{error: error}) do
        conn
        |> put_status(422)
        |> render(:error, error: error)
      end
      def password_update_error(conn, %{changeset: changeset}) do
        conn
        |> put_status(422)
        |> render(:error, changeset: changeset)
      end

      def password_update_success(conn, %{params: params, info: info}) do
        conn
        |> render(:password, info: info)
      end

      def invitation_create_success(conn, opts \\ %{})
      def invitation_create_success(conn, %{info: info}) do
        conn
        |> put_status(201)
        |> render(:invitation, info: info)
      end

      def invitation_create_error(conn, opts \\ %{})
      def invitation_create_error(conn, %{changeset: changeset}) do
        conn
        |> put_status(422)
        |> render(:error, changeset: changeset)
      end

      def invitation_resend_error(conn, opts \\ %{})
      def invitation_resend_error(conn, %{error: error}) do
        conn
        |> put_status(422)
        |> render(:error, error: error)
      end

      def invitation_resend_success(conn, opts \\ %{})
      def invitation_resend_success(conn, %{info: info}) do
        conn
        |> put_status(200)
        |> render(:invitation, info: info)
      end

      def invitation_create_user_error(conn, opts \\ %{})
      def invitation_create_user_error(conn, %{error: error}) do
        conn
        |> put_status(422)
        |> render(:error, error: error)
      end
      def invitation_create_user_error(conn, %{changeset: changeset}) do
        conn
        |> put_status(422)
        |> render(:error, changeset: changeset)
      end

      def invitation_create_user_success(conn, opts \\ %{})
      def invitation_create_user_success(conn, %{}) do
        conn
        |> send_resp(201, "")
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
