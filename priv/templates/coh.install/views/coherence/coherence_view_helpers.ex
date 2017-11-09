defmodule <%= web_base %>.Coherence.ViewHelpers do
  @moduledoc """
  Helper functions for Coherence Views.
  """
  use Phoenix.HTML
  alias Coherence.Config
  import <%= web_base %>.Gettext

  @type conn :: Plug.Conn.t
  @type schema :: Ecto.Schema.t

  @seperator {:safe, "&nbsp; | &nbsp;"}
  @helpers <%= web_base %>.Router.Helpers

  @recover_link  dgettext("coherence", "Forgot your password?")
  @unlock_link   dgettext("coherence", "Send an unlock email")
  @register_link dgettext("coherence", "Need An Account?")
  @invite_link   dgettext("coherence", "Invite Someone")
  @confirm_link  dgettext("coherence", "Resend confirmation email")
  @signin_link   dgettext("coherence", "Sign In")
  @signout_link  dgettext("coherence", "Sign Out")

  @doc """
  Create coherence template links.

  Generates links if the appropriate option is installed. This function
  can be used to:

  * create links for the new session page `:new_session`
  * create links for your layout template `:layout`


  Defaults are provided based on the options configured for Coherence.
  However, the defaults can be overridden by passing the following options.

  ## Customize the links

  ### :new_session Options

  * :recover - customize the recover link (#{@recover_link})
  * :unlock - customize the unlock link (#{@unlock_link})
  * :register - customize the register link (#{@register_link})
  * :confirm - customize the confirm link (#{@confirm_link})

  ### :layout Options

  * :list_tag - customize the list tag (:li)
  * :signout_class - customize the class on the signout link ("navbar-form")
  * :signin - customize the signin link text (#{@signin_link})
  * :signout - customize the signout link text (#{@signout_link})
  * :register - customize the register link text (#{@register_link})

  ### Disable links

  If you set an option to false, the link will not be shown. For example, to
  disable the register link on the layout, use the following in your layout template:

      coherence_links(conn, :layout, register: false)

  ## Examples

      coherence_links(conn, :new_session)
      Generates: #{@recover_link}  #{@unlock_link} #{@register_link} #{@confirm_link}

      coherence_links(conn, :new_session, recover: "Password reset", register: false
      Generates: Password reset  #{@unlock_link}

      coherence_links(conn, :layout)             # when logged in
      Generates: User's Name  #{@signout_link}

      coherence_links(conn, :layout)             # when not logged in
      Generates: #{@register_link}  #{@signin_link}
  """
  @spec coherence_links(conn, atom, Keyword.t) :: tuple
  def coherence_links(conn, which, opts \\ [])
  def coherence_links(conn, :new_session, opts) do
    recover_link  = Keyword.get opts, :recover, @recover_link
    unlock_link   = Keyword.get opts, :unlock, @unlock_link
    register_link = Keyword.get opts, :register, @register_link
    confirm_link  = Keyword.get opts, :confirm, @confirm_link

    user_schema = Coherence.Config.user_schema
    [
      recover_link(conn, user_schema, recover_link),
      unlock_link(conn, user_schema, unlock_link),
      register_link(conn, user_schema, register_link),
      confirmation_link(conn, user_schema, confirm_link)
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
        content_tag(list_tag, profile_link(current_user, conn)),
        content_tag(list_tag, signout_link(conn, signout, signout_class))
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
  @spec coherence_path(module, atom, conn, atom) :: String.t
  def coherence_path(module, route_name, conn, action) do
    apply(module, route_name, [conn, action])
  end
  def coherence_path(module, route_name, conn, action, opts) do
    apply(module, route_name, [conn, action, opts])
  end

  defp concat([], acc), do: Enum.reverse(acc)
  defp concat([h|t], []), do: concat(t, [h])
  defp concat([h|t], acc), do: concat(t, [h, @seperator | acc])

  @spec recover_link(conn, module, false | String.t) :: [any] | []
  def recover_link(_conn, _user_schema, false), do: []
  def recover_link(conn, user_schema, text) do
    if user_schema.recoverable?, do: [recover_link(conn, text)], else: []
  end

  @spec recover_link(conn, String.t) :: tuple
  def recover_link(conn, text \\ @recover_link), do:
    link(text, to: coherence_path(@helpers, :password_path, conn, :new))

  @spec register_link(conn, module, false | String.t) :: [any] | []
  def register_link(_conn, _user_schema, false), do: []
  def register_link(conn, user_schema, text) do
    if user_schema.registerable?, do: [register_link(conn, text)], else: []
  end

  @spec register_link(conn, String.t) :: tuple
  def register_link(conn, text \\ @register_link), do:
    link(text, to: coherence_path(@helpers, :registration_path, conn, :new))

  @spec unlock_link(conn, module, false | String.t) :: [any] | []
  def unlock_link(_conn, _user_schema, false), do: []
  def unlock_link(conn, _user_schema, text) do
    if conn.assigns[:locked], do: [unlock_link(conn, text)], else: []
  end

  @spec unlock_link(conn, String.t) :: tuple
  def unlock_link(conn, text \\ @unlock_link), do:
    link(text, to: coherence_path(@helpers, :unlock_path, conn, :new))

  @spec invitation_link(conn, String.t) :: tuple
  def invitation_link(conn, text \\ @invite_link) do
    link text, to: coherence_path(@helpers, :invitation_path, conn, :new)
  end

  @spec signout_link(conn, String.t, String.t) :: tuple
  def signout_link(conn, text \\ @signout_link, signout_class \\ "") do
    link(text, to: coherence_path(@helpers, :session_path, conn, :delete), method: :delete, class: signout_class)
  end

  @spec confirmation_link(conn, module, false | String.t) :: [any] | []
  def confirmation_link(_conn, _user_schema, false), do: []
  def confirmation_link(conn, user_schema, text) do
    if user_schema.confirmable?, do: [confirmation_link(conn, text)], else: []
  end

  @spec confirmation_link(conn, String.t) :: tuple
  def confirmation_link(conn, text \\ @confirm_link) do
    link(text, to: coherence_path(@helpers, :confirmation_path, conn, :new))
  end

  @spec required_label(atom, String.t | atom, Keyword.t) :: tuple
  def required_label(f, name, opts \\ []) do
    label f, name, opts do
      [
        "#{humanize(name)}\n",
        content_tag(:abbr, "*", class: "required", title: "required")
      ]
    end
  end

  @spec current_user(conn) :: schema
  def current_user(conn) do
    Coherence.current_user(conn)
  end

  @spec logged_in?(conn) :: boolean
  def logged_in?(conn) do
    Coherence.logged_in?(conn)
  end


  defp profile_link(current_user, conn) do
    if Config.user_schema.registerable? do
      link current_user.name, to: coherence_path(@helpers, :registration_path, conn, :show)
    else
      current_user.name
    end
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # Because error messages were defined within Ecto, we must
    # call the Gettext module passing our Gettext backend. We
    # also use the "errors" domain as translations are placed
    # in the errors.po file.
    # Ecto will pass the :count keyword if the error message is
    # meant to be pluralized.
    # On your own code and templates, depending on whether you
    # need the message to be pluralized or not, this could be
    # written simply as:
    #
    #     dngettext "errors", "1 file", "%{count} files", count
    #     dgettext "errors", "is invalid"
    #
    if count = opts[:count] do
      Gettext.dngettext(<%= web_base %>.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(<%= web_base %>.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Generates an error string from changeset errors.
  """
  def error_string_from_changeset(changeset) do
    Enum.map(changeset.errors, fn {k, v} ->
      "#{Phoenix.Naming.humanize(k)} #{translate_error(v)}"
    end) |> Enum.join(". ")
  end
end
