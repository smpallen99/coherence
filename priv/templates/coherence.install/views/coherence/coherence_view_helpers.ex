defmodule <%= base %>.Coherence.ViewHelpers do
  use Phoenix.HTML
  import <%= base %>.Router.Helpers
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

  if Config.user_schema.invitable? do
    def invitation_link(conn) do
      link "Invite Someone", to: invitation_path(conn, :new)
    end
  else
    def invitation_link(_conn), do: ""
  end

  if Config.user_schema.unlockable_with_token? do
    defp unlock_link(conn, _user_schema) do
      if conn.assigns[:locked] do
        [link("Send an unlock email", to: unlock_path(conn, :new))]
      else
        []
      end
    end
  else
    defp unlock_link(_conn, _user_schema), do: []
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
