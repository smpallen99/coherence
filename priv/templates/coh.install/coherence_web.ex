defmodule <%= base %>.Coherence.Web do
  @moduledoc false

  def view do
    quote do
      <%
      web_prefix = Mix.Phoenix.web_prefix(otp_app)
      root_path = Path.join(web_prefix, "templates/coherence")
      %>
      use Phoenix.View, root: "<%= root_path %>"
      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import <%= base %>.Web.Router.Helpers
      import <%= base %>.Web.ErrorHelpers
      import <%= base %>.Web.Gettext
      import <%= base %>.Coherence.ViewHelpers
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
