defmodule CoherenceTest.Authentication.IpAddress do
  use ExUnit.Case, async: true
  use Plug.Test
  alias Coherence.Authentication.IpAddress

  @error_msg ~s'{"error":"authentication required"}'

  defmodule IpPlug do
    use Plug.Builder
    import Plug.Conn

    plug Coherence.Authentication.IpAddress,
      allow: ~w(192.168.1.200 10.10.10.10 47.21.0.0/16),
      deny: ~w(10.10.15.10 10.10.15.11 48.24.254.0/255.255.254.0),
      error: ~s'{"error":"authentication required"}'
    plug :index

    defp index(conn, _opts), do: send_resp(conn, 200, "Authorized")
  end

  defmodule IpAllowAllPlug do
    use Plug.Builder
    import Plug.Conn

    plug Coherence.Authentication.IpAddress,
      allow: ~w(0.0.0.0/0),
      deny: ~w(48.24.254.0/255.255.254.0),
      error: ~s'{"error":"authentication required"}'
    plug :index

    defp index(conn, _opts), do: send_resp(conn, 200, "Authorized")
  end

  defp call(plug, params) do
    conn(:get, "/", params)
    |> plug.call([])
  end

  defp call(plug, params, ip_address) do
    conn(:get, "/", params)
    |> struct(peer: {ip_address, 4000})
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
  end

  defp assert_user_data(conn, user_data) do
    assert conn.assigns[:current_user] ==  user_data
  end

  setup do
    # Coherence.CredentialStore.Server.put_credentials("secret_token", %{id: 1, role: :admin})
    :ok
  end

  test "request without credentials" do
    conn = call(IpPlug, [])
    assert_unauthorized conn, @error_msg
  end

  test "request with invalid IP" do
    conn = call(IpPlug, [], {192,168,1,199})
    assert_unauthorized conn, @error_msg
  end

  test "request with valid IP" do
    conn = call(IpPlug, [], {192,168,1,200})
    assert_authorized conn, "Authorized"
  end

  test "request with IP in deny" do
    conn = call(IpPlug, [], {10,10,15,11})
    assert_unauthorized conn, @error_msg
  end

  test "request not in allow subnet" do
    conn = call(IpPlug, [], {47,22,15,11})
    assert_unauthorized conn, @error_msg
  end

  test "request in allow subnet" do
    user = %{id: 1, role: :admin}
    IpAddress.add_credentials {47,21,15,11}, user
    conn = call(IpPlug, [], {47,21,15,11})
    assert_authorized conn, "Authorized"
    assert_user_data conn, user
  end

  test "request in deny subnet" do
    conn = call(IpAllowAllPlug, [], {48,24,254,11})
    assert_unauthorized conn, @error_msg
  end

  test "request not in deny subnet" do
    conn = call(IpAllowAllPlug, [], {48,24,253,11})
    assert_authorized conn, "Authorized"
    conn = call(IpAllowAllPlug, [], {10,24,255,11})
    assert_authorized conn, "Authorized"
  end
end
