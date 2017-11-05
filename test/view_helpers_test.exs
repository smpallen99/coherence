defmodule CoherenceTestWeb.ViewHelpers do
  use TestCoherence.ConnCase
  import Plug.Conn
  alias TestCoherenceWeb.ViewHelpers
  alias TestCoherence.User
  import Phoenix.HTML, only: [safe_to_string: 1]

  @recover_link  "Forgot your password?"
  @unlock_link   "Send an unlock email"
  @register_link "Need An Account?"
  @confirmation_link "Resend confirmation email"
  @signin_link   "Sign In"
  @signout_link  "Sign Out"

  setup do
    Application.put_env :coherence, :opts, [:confirmable, :authenticatable, :recoverable,
      :lockable, :trackable, :unlockable_with_token, :invitable, :registerable]
    user = %User{name: "test", email: "test@example.com", id: 1}
    conn = %Plug.Conn{}
    |> assign(:current_user, user)
    {:ok, conn: conn, user: user}
  end

  @helpers Module.concat(Application.get_env(:coherence, :web_module), Router.Helpers)

  test "coherence_path", %{conn: conn} do
    assert ViewHelpers.coherence_path(@helpers, :unlock_path, conn, :new) == "/unlocks/new"
    assert ViewHelpers.coherence_path(@helpers, :registration_path, conn, :new) == "/registrations/new"
    assert ViewHelpers.coherence_path(@helpers, :session_path, conn, :new) == "/sessions/new"
  end

  test "unlock_link", %{conn: conn} do
    assert ViewHelpers.unlock_link(conn, "Unlock")
    |> floki_link == {"/unlocks/new", "Unlock"}

    user_schema = Config.user_schema
    assert ViewHelpers.unlock_link(conn, user_schema, false) == []
    assert ViewHelpers.unlock_link(conn, user_schema, "Unlock") == []
    result = conn
    |> Plug.Conn.assign(:locked, true)
    |> ViewHelpers.unlock_link(user_schema, "Send Unlock link")
    |> hd
    assert floki_link(result) == {"/unlocks/new", "Send Unlock link"}
  end

  test "coherence_links :new_session defaults", %{conn: conn} do
    conn = Plug.Conn.assign conn, :locked, true

    [result1, "&nbsp; | &nbsp;", result2, "&nbsp; | &nbsp;",  result3, "&nbsp; | &nbsp;", result4] =
      ViewHelpers.coherence_links(conn, :new_session)
      |> Enum.map(&Phoenix.HTML.safe_to_string/1)

    assert floki_link(result1) == {"/passwords/new", @recover_link}
    assert floki_link(result2) == {"/unlocks/new", @unlock_link}
    assert floki_link(result3) == {"/registrations/new", @register_link}
    assert floki_link(result4) == {"/confirmations/new", @confirmation_link}
  end

  test "coherence_links :new_session no register", %{conn: conn} do
    conn = Plug.Conn.assign conn, :locked, true

    [result1, "&nbsp; | &nbsp;", result2, "&nbsp; | &nbsp;", result3] =
      ViewHelpers.coherence_links(conn, :new_session, register: false)
      |> Enum.map(&Phoenix.HTML.safe_to_string/1)

    assert floki_link(result1) == {"/passwords/new", @recover_link}
    assert floki_link(result2) == {"/unlocks/new", @unlock_link}
    assert floki_link(result3) == {"/confirmations/new", @confirmation_link}
  end

  test "coherence_links :new_session not locked no register", %{conn: conn} do

    [result1, "&nbsp; | &nbsp;", result2] =
      ViewHelpers.coherence_links(conn, :new_session, register: false)
      |> Enum.map(&Phoenix.HTML.safe_to_string/1)

    assert floki_link(result1) == {"/passwords/new", @recover_link}
    assert floki_link(result2) == {"/confirmations/new", @confirmation_link}
  end

  test "coherence_links :layout signed in", %{conn: conn} do
    [item1, item2] = ViewHelpers.coherence_links(conn, :layout)

    result1 = item1 |> safe_to_string
    result2 = item2 |> safe_to_string

    assert Floki.find(result1, "li") |> Floki.text == "test"
    assert Floki.find(result2, "li a") |> Floki.text == @signout_link
  end

  test "coherence_links :layout not signed" do
    conn = %Plug.Conn{}
    [item1, item2] = ViewHelpers.coherence_links(conn, :layout, register: "New Account", signin: "Login")

    result1 = item1 |> safe_to_string
    result2 = item2 |> safe_to_string

    assert Floki.find(result1, "li") |> Floki.text == "New Account"
    assert Floki.find(result2, "li a") |> Floki.text == "Login"
  end

  test "coherence_links :layout not signed no register" do
    conn = %Plug.Conn{}
    assert ViewHelpers.coherence_links(conn, :layout, register: false)
    |> floki_link == {"/sessions/new", @signin_link}
  end

end
