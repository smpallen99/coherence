defmodule <%= base %>.Coherence.Web do
  @moduledoc false

  def view do
    quote do
      use Phoenix.View, root: "<%= Path.join(Mix.Phoenix.web_path(otp_app), "templates/coherence") %>"
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

  def controller do
    quote do
      use Phoenix.Controller, except: [layout_view: 2] #, namespace: BlogPhx.Web
      use Coherence.Config
      use Timex

      import Ecto
      import Ecto.Query
      import Plug.Conn
      import <%= base %>.Web.Router.Helpers
      import <%= base %>.Web.Gettext
      import Coherence.ControllerHelpers

      alias Coherence.Config
      alias Coherence.ControllerHelpers, as: Helpers

      require Redirects
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
