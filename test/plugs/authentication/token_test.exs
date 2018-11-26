defmodule CoherenceTest.Authentication.Token do
  use ExUnit.Case, async: true
  use Plug.Test

  @error_msg ~s'{"error":"authentication required"}'

  defmodule ParamPlug do
    use Plug.Builder
    import Plug.Conn

    plug Coherence.Authentication.Token, source: :params, param: "auth_token", error: ~s'{"error":"authentication required"}'
    plug :index

    defp index(conn, _opts), do: send_resp(conn, 200, "Authorized")
  end

  defmodule HeaderPlug do
    use Plug.Builder
    import Plug.Conn

    plug Coherence.Authentication.Token, source: :header, param: "x-auth-token", error: ~s'{"error":"authentication required"}'
    plug :index

    defp index(conn, _opts), do: send_resp(conn, 200, "Authorized")
  end

  defmodule ParamErrorHandlerPlug do
    use Plug.Builder
    import Plug.Conn

    plug Coherence.Authentication.Token, source: :params, param: "auth_token", error: &TestCoherence.TestHelpers.handler/1
  end

  defmodule HeaderErrorHandlerPlug do
    use Plug.Builder
    import Plug.Conn

    plug Coherence.Authentication.Token, source: :header, param: "x-auth-token", error: &TestCoherence.TestHelpers.handler/1
  end

  defp call(plug, params) do
    conn(:get, "/", params)
    |> plug.call([])
  end

  defp call(plug, params, token) do
    conn(:get, "/", params)
    |> put_req_header("x-auth-token", token)
    |> plug.call([])
  end

  defp assert_unauthorized(conn, content) do
    assert conn.status == 401
    assert conn.resp_body == content
    refute conn.assigns[:current_user]
  end

  defp assert_authorized(conn, content) do
    assert conn.status == 200
    assert conn.resp_body == content
    assert conn.assigns[:current_user] == %{id: 1, role: :admin}
  end

  defp assert_error_handler_called(conn) do
    assert conn.status == 418
    assert conn.resp_body == "I'm a teapot"
    assert conn.assigns[:error_handler_called]
  end

  defp auth_param(creds), do: {"auth_token", creds}

  setup do
    Coherence.CredentialStore.Server.put_credentials("secret_token", %{id: 1, role: :admin})
    :ok
  end

  test "request without credentials using header-based auth" do
    conn = call(HeaderPlug, [])
    assert_unauthorized conn, @error_msg
  end

  test "request with invalid credentials using header-based auth" do
    conn = call(HeaderPlug, [], "invalid_token")
    assert_unauthorized conn, @error_msg
  end

  test "request with valid credentials using header-based auth" do
    conn = call(HeaderPlug, [], "secret_token")
    assert_authorized conn, "Authorized"
  end

  test "request without credentials using params-based auth" do
    conn = call(ParamPlug, [])
    assert_unauthorized conn, @error_msg
  end

  test "request with invalid credentials using params-based auth" do
    conn = call(ParamPlug, [auth_param("invalid_token")])
    assert_unauthorized conn, @error_msg
  end

  test "request with valid credentials using params-based auth" do
    conn = call(ParamPlug, [auth_param("secret_token")])
    assert_authorized conn, "Authorized"
  end

  test "request without credentials using header-based auth and error handler" do
    call(HeaderErrorHandlerPlug, [])
    |> assert_error_handler_called
  end

  test "request with invalid credentials using header-based auth and error handler" do
    call(HeaderErrorHandlerPlug, [], "invalid_token")
    |> assert_error_handler_called
  end

  test "request without credentials using params-based auth and error handler" do
    call(ParamErrorHandlerPlug, [])
    |> assert_error_handler_called
  end

  test "request with invalid credentials using params-based auth and error handler" do
    call(ParamErrorHandlerPlug, [auth_param("invalid_token")])
    |> assert_error_handler_called
  end
end
