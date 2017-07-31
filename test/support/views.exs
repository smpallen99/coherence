defmodule Coherence.CoherenceView do
  use Phoenix.HTML
  use Phoenix.View, root: "web/templates/coherence"
  import TestCoherenceWeb.Router.Helpers

  @seperator {:safe, "&nbsp; | &nbsp;"}

  def coherence_links(conn, :new_session) do
    user_schema = Coherence.Config.user_schema
    [
      recovery_link(conn, user_schema),
      unlock_link(conn, user_schema)
    ]
    |> List.flatten
    |> concat([])
  end

  defp concat([], acc), do: Enum.reverse(acc)
  defp concat([h|t], []), do: concat(t, [h])
  defp concat([h|t], acc), do: concat(t, [h, @seperator | acc])

  defp recovery_link(conn, user_schema) do
    if user_schema.recoverable? do
      [link("Forgot Your Password?", to: password_path(conn, :new))]
    else
      []
    end
  end

  defp unlock_link(conn, _user_schema) do
    if conn.assigns[:locked] do
      [link("Send an unlock email", to: unlock_path(conn, :new))]
    else
      []
    end
  end
end

defmodule Coherence.LayoutView do
  use TestCoherenceWeb.Coherence, :view
  # import TestCoherence.Web.Router.Helpers
end
defmodule TestCoherenceWeb.Coherence.InvitationView do
  use TestCoherenceWeb.Coherence, :view
  def render("new.html", params) do
    "new data: #{inspect params}"
  end
end
defmodule TestCoherenceWeb.Coherence.SessionView do
  use TestCoherenceWeb.Coherence, :view
  def render("new.html", _params), do: "new session"
end

defmodule TestCoherenceWeb.ErrorView do
  def render("500.html", _changeset), do: "500.html"
  def render("400.html", _changeset), do: "400.html"
end
