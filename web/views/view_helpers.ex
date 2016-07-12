defmodule Coherence.ViewHelpers do
  @moduledoc """
  Helper functions for Coherence Views.
  """
  use Phoenix.HTML
  alias Coherence.Config

  @seperator {:safe, "&nbsp; | &nbsp;"}
  @helpers Module.concat(Application.get_env(:coherence, :module), Router.Helpers)

  @recover_link  "Forgot your password?"
  @unlock_link   "Send an unlock email"
  @register_link "Need An Account?"
  @invite_link   "Invite Someone"
  @signin_link   "Sign In"
  @signout_link  "Sign Out"

  @doc """
  Create coherence template links.

  Generates links if the appropriate option is installed.

  ## Examples

      coherence_links(conn, :new_session)
      Generates: #{@recover_link}  #{@unlock_link} #{@register_link}

      coherence_links(conn, :new_session, recover: "Password reset", register: false
      Generates: Password reset  #{@unlock_link}

      coherence_links(conn, :layout)             # when logged in
      Generates: User's Name  #{@signout_link}

      coherence_links(conn, :layout)             # when not logged in
      Generates: #{@register_link}  #{@signin_link}

  """
  def coherence_links(conn, which, opts \\ [])
  def coherence_links(conn, :new_session, opts) do
    recover?  = Keyword.get opts, :recover, @recover_link
    unlock?   = Keyword.get opts, :unlock, @unlock_link
    register? = Keyword.get opts, :register, @register_link

    user_schema = Coherence.Config.user_schema
    [
      recover_link(conn, user_schema, recover?),
      unlock_link(conn, user_schema, unlock?),
      register_link(conn, user_schema, register?)
    ]
    |> List.flatten
    |> concat([])
  end

  def coherence_links(conn, :layout, opts) do
    list_tag      = Keyword.get opts, :list_tag, :li
    signout_class = Keyword.get opts, :signout_class, "navbar-form"
    signin        = Keyword.get opts, :signin, @signin_link
    signout       = Keyword.get opts, :signout, @signout_link
    register      = Keyword.get opts, :register, @register_link

    if Coherence.logged_in?(conn) do
      current_user = Coherence.current_user(conn)
      [
        content_tag(list_tag, current_user.name),
        content_tag(list_tag,
          link(signout, to: coherence_path(@helpers, :session_path, conn, :delete, current_user), method: :delete, class: signout_class))
      ]
    else
      signin_link = content_tag(list_tag, link(signin, to: coherence_path(@helpers, :session_path, conn, :new)))
      if Config.has_option(:registerable) && register do
        [content_tag(list_tag, link(register, to: coherence_path(@helpers, :registration_path, conn, :new))), signin_link]
      else
        signin_link
      end
    end
  end

  @doc """
  Helper to avoid compile warnings when options are disabled.
  """
  def coherence_path(module, route_name, conn, action) do
    apply(module, route_name, [conn, action])
  end
  def coherence_path(module, route_name, conn, action, opts) do
    apply(module, route_name, [conn, action, opts])
  end

  defp concat([], acc), do: Enum.reverse(acc)
  defp concat([h|t], []), do: concat(t, [h])
  defp concat([h|t], acc), do: concat(t, [h, @seperator | acc])

  def recover_link(_conn, _user_schema, false), do: []
  def recover_link(conn, user_schema, text) do
    if user_schema.recoverable?, do: [recover_link(conn, text)], else: []
  end
  def recover_link(conn, text \\ @recover_link), do:
    link(text, to: coherence_path(@helpers, :password_path, conn, :new))

  def register_link(_conn, _user_schema, false), do: []
  def register_link(conn, user_schema, text) do
    if user_schema.registerable?, do: [register_link(conn, text)], else: []
  end
  def register_link(conn, text \\ @register_link), do:
    link(text, to: coherence_path(@helpers, :registration_path, conn, :new))

  def unlock_link(_conn, _user_schema, false), do: []
  def unlock_link(conn, _user_schema, text) do
    if conn.assigns[:locked], do: [unlock_link(conn, text)], else: []
  end
  def unlock_link(conn, text \\ @unlock_link), do:
    link(text, to: coherence_path(@helpers, :unlock_path, conn, :new))

  def invitation_link(conn, text \\ @invite_link) do
    link text, to: coherence_path(@helpers, :invitation_path, conn, :new)
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
