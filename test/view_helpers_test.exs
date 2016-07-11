defmodule CoherenceTest.ViewHelpers do
  use TestCoherence.ConnCase
  import Plug.Conn
  alias Coherence.ViewHelpers
  alias TestCoherence.User

  setup do
    user = %User{name: "test", email: "test@example.com", id: 1}
    conn = %Plug.Conn{}
    |> assign(:current_user, user)
    {:ok, conn: conn, user: user}
  end


  test "coherence_links :new_session", %{conn: conn} do
    assert ViewHelpers.coherence_links(conn, :new_session) |> hd |>
      Phoenix.HTML.safe_to_string |> Floki.find("a[href]") ==
      [{"a", [{"href", "/passwords/new"}], ["Forgot Your Password?"]}]
  end

  test "coherence_links :layout signed in", %{conn: conn} do
    [item1, item2] = ViewHelpers.coherence_links(conn, :layout)

    result1 = item1 |> Phoenix.HTML.safe_to_string
    result2 = item2 |> Phoenix.HTML.safe_to_string

    assert Floki.find(result1, "li") |> Floki.text == "test"
    assert Floki.find(result2, "li form a") |> Floki.text == "Sign Out"
  end

  test "coherence_links :layout not signed" do
    conn = %Plug.Conn{}
    [item1, item2] = ViewHelpers.coherence_links(conn, :layout, register: "New Account", signin: "Login")

    result1 = item1 |> Phoenix.HTML.safe_to_string
    result2 = item2 |> Phoenix.HTML.safe_to_string

    assert Floki.find(result1, "li") |> Floki.text == "New Account"
    assert Floki.find(result2, "li a") |> Floki.text == "Login"
  end

end
