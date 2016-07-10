defmodule Coherence.ViewHelpers do
  use Phoenix.HTML
  alias Coherence.Router.Helpers
  alias Coherence.Config

  @seperator {:safe, "&nbsp; | &nbsp;"}
  @helpers Module.concat(Application.get_env(:coherence, :module), Router.Helpers)

  def coherence_links(conn, which, opts \\ [])
  def coherence_links(conn, :new_session, opts) do
    user_schema = Coherence.Config.user_schema
    [
      recovery_link(conn, user_schema),
      unlock_link(conn, user_schema)
    ]
    |> List.flatten
    |> concat([])
  end

  def coherence_links(conn, :layout, opts) do
    list_tag = opts[:list_tag] || :li
    signout_class = opts[:signout_class] || "navbar-form"
    signin = opts[:signin] || "Sign In"
    signout = opts[:signout] || "Sign Out"
    register = opts[:register] || "Register"

    if Coherence.logged_in?(conn) do
      current_user = Coherence.current_user(conn)
      [
        content_tag(list_tag, current_user.name),
        content_tag(list_tag,
          link(signout, to: coherence_path(@helpers, :session_path, conn, :delete, current_user), method: :delete, class: signout_class))
      ]
    else
      signin_link = content_tag(list_tag, link(signin, to: coherence_path(@helpers, :session_path, conn, :new)))
      if Config.has_option(:registerable) do
        [content_tag(list_tag, link(register, to: coherence_path(@helpers, :registration_path, conn, :new))), signin_link]
      else
        signin_link
      end
    end
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
      [link("Forgot Your Password?", to: coherence_path(@helpers, :password_path, conn, :new))]
    else
      []
    end
  end

  def invitation_link(conn) do
    link "Invite Someone", to: coherence_path(@helpers, :invitation_path, conn, :new)
  end

  def unlock_link(conn, _user_schema) do
    if conn.assigns[:locked] do
      [link("Send an unlock email", to: coherence_path(@helpers, :unlock_path, conn, :new))]
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
