defmodule <%= base %>.Coherence.ViewHelpers do
  use Phoenix.HTML
  alias <%= base %>.Router.Helpers
  alias Coherence.Config

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

  defp coherence_path(module, route_name, conn, action) do
    apply(module, route_name, [conn, action])
  end
  defp coherence_path(module, route_name, conn, action, opts) do
    apply(module, route_name, [conn, action, opts])
  end

  defp concat([], acc), do: Enum.reverse(acc)
  defp concat([h|t], []), do: concat(t, [h])
  defp concat([h|t], acc), do: concat(t, [h, @seperator | acc])

  defp recovery_link(conn, user_schema) do
    if user_schema.recoverable? do
      [link("Forgot Your Password?", to: coherence_path(Helpers, :password_path, conn, :new))]
    else
      []
    end
  end

  def invitation_link(conn) do
    link "Invite Someone", to: coherence_path(Helpers, :invitation_path, conn, :new)
  end

  def unlock_link(conn, _user_schema) do
    if conn.assigns[:locked] do
      [link("Send an unlock email", to: coherence_path(Helpers, :unlock_path, conn, :new))]
    else
      []
    end
  end

  def required_label(f, name, opts \\ []) do
    label f, name, opts do
      [
        "#{humanize(name)}\n",
        content_tag(:abbr, "*", class: "required", title: "required")
      ]
    end
  end

end
