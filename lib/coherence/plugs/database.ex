# defmodule Coherence.Authentication.Database do
#   @moduledoc """
#     Implements Database authentication. To use add:

#       plug Coherence.Authentication.Database, login: &MyController.login_callback/1

#     to your pipeline. This module is derived from https://github.com/lexmag/blaguth
#   """

#   @session_key Application.get_env(:coherence, :database_session_key, "database_auth")

#   @behaviour Plug
#   import Plug.Conn
#   import Coherence.Authentication.Utils

#   @doc """
#     Create a login for a user. `user_data` can be any term but must not be `nil`.
#   """
#   def create_login(conn, user_data, id_key \\ :id) do
#     id = UUID.uuid1
#     id |> Coherence.CredentialStore.put_credentials(user_data, id_key)
#     put_session(conn, @session_key, id)
#   end

#   @doc """
#     Delete a login.
#   """
#   def delete_login(conn) do
#     case get_session(conn, @session_key) do
#       nil -> conn

#       key ->
#         Coherence.CredentialStore.delete_credentials(key)
#         put_session(conn, @session_key, nil)
#         |> put_session("user_return_to", nil)
#     end
#     |> delete_token_session
#   end

#   @doc """
#     Fetch user data from the credential store
#   """
#   def get_user_data(conn) do
#     get_session(conn, @session_key)
#     |> Coherence.CredentialStore.get_user_data
#   end

#   def init(opts) do
#     error = Keyword.get(opts, :error, "HTTP Authentication Required")
#     login = Keyword.get(opts, :login, &Coherence.SessionController.login_callback/1)
#     # unless login do
#     #   raise RuntimeError, message: "Coherence.Database requires a login redirect callback"
#     # end
#     %{login: login,  error: error}
#   end

#   def call(conn, opts) do
#     unless get_authenticated_user(conn) do
#       conn
#       |> get_session_data
#       |> verify_auth_key
#       |> assert_login(opts[:login])
#     else
#       conn
#     end
#   end

#   defp get_session_data(conn) do
#     {conn, get_session(conn, @session_key) }
#   end

#   defp verify_auth_key({conn, nil}), do: {conn, nil}
#   defp verify_auth_key({conn, auth_key}), do: {conn, Coherence.CredentialStore.get_user_data(auth_key)}

#   defp assert_login({conn, nil}, login) do
#     put_session(conn, "user_return_to", Path.join(["/" | conn.path_info]))
#     |> login.()
#   end
#   defp assert_login({conn, user_data}, _login), do: assign_user_data(conn, user_data)
# end
defmodule Coherence.Authentication.Database do
  @moduledoc """
    Implements Database authentication. To use add:

      plug Coherence.Authentication.Database, login: &MyController.login_callback/1

    to your pipeline. This module is derived from https://github.com/lexmag/blaguth
  """

  @session_key Application.get_env(:coherence, :database_session_key, "database_auth")

  @behaviour Plug
  import Plug.Conn
  import Coherence.Authentication.Utils
  alias Coherence.{Rememberable, Config}

  @doc """
    Create a login for a user. `user_data` can be any term but must not be `nil`.
  """
  def create_login(conn, user_data, id_key \\ :id) do
    id = UUID.uuid1
    id |> Coherence.CredentialStore.put_credentials(user_data, id_key)
    put_session(conn, @session_key, id)
  end

  @doc """
    Delete a login.
  """
  def delete_login(conn) do
    case get_session(conn, @session_key) do
      nil -> conn

      key ->
        Coherence.CredentialStore.delete_credentials(key)
        put_session(conn, @session_key, nil)
        |> put_session("user_return_to", nil)
    end
    |> delete_token_session
  end

  # @doc """
  #   Fetch user data from the credential store
  # """
  # def get_user_data(conn) do
  #   get_session(conn, @session_key)
  #   |> Coherence.CredentialStore.get_user_data
  # end

  def init(opts) do
    # TODO: need to fix the default login callback
    %{
      login: Keyword.get(opts, :login, &Coherence.SessionController.login_callback/1),
      error: Keyword.get(opts, :error, "HTTP Authentication Required"),
      db_model: Keyword.get(opts, :db_model),
      id_key: Keyword.get(opts, :id, :id),
      login_key: Keyword.get(opts, :login_cookie, Config.login_cookie),
      rememberable: Keyword.get(opts, :rememberable, Config.user_schema.rememberable?),
      cookie_expire: Keyword.get(opts, :login_cookie_expire_hours, Config.rememberable_cookie_expire_hours) * 60 * 60
    }
  end

  def call(conn, opts) do
    # IO.puts ".. opts: #{inspect opts}"
    unless get_authenticated_user(conn) do
      conn
      |> get_session_data
      |> verify_auth_key(opts)
      |> verify_rememberable(opts)
      |> assert_login(opts[:login])
    else
      conn
    end
  end

  defp get_session_data(conn) do
    {conn, get_session(conn, @session_key) }
  end

  defp verify_rememberable({conn, nil}, %{rememberable: true, login_key: key} = opts) do
    case conn.cookies[key] do
      nil -> {conn, nil}
      cookie ->
        case String.split cookie, " " do
          [id, series, token] ->
            case opts[:rememberable_callback] do
              nil ->
                Coherence.SessionController.remberable_callback(conn, id, series, token, opts)
              fun ->
                fun.(conn, id, series, token, opts)
            end
          _ -> {conn, nil}   # invalid cookie
        end
    end
  end
  defp verify_rememberable(other, _opts), do: other

  defp verify_auth_key({conn, nil}, _), do: {conn, nil}
  defp verify_auth_key({conn, auth_key}, %{db_model: db_model, id_key: id_key}),
    do: {conn, Coherence.CredentialStore.get_user_data(auth_key, db_model, id_key)}

  defp assert_login({conn, nil}, login) when is_function(login) do
    put_session(conn, "user_return_to", Path.join(["/" | conn.path_info]))
    |> login.()
  end
  defp assert_login({conn, user_data}, _), do: assign_user_data(conn, user_data)
  defp assert_login(conn, _), do: conn
end
