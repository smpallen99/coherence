defmodule Coherence.Router do
  @moduledoc """
  Handles routing for Coherence.

  ## Usage

  Add the following to your `web/router.ex` file

      defmodule MyProject.Router do
        use MyProject.Web, :router
        use Coherence.Router         # Add this

        pipeline :browser do
          plug :accepts, ["html"]
          # ...
          plug Coherence.Authentication.Session           # Add this
        end

        pipeline :protected do
          plug :accepts, ["html"]
          # ...
          plug Coherence.Authentication.Session, protected: true
        end

        scope "/" do
          pipe_through :browser
          coherence_routes
        end

        scope "/" do
          pipe_through :protected
          coherence_routes :protected
        end
        # ...
      end

  Alternatively, you may want to use the login plug in individual controllers. In
  this case, you can have one pipeline, one scope and call `coherence_routes :all`.
  In this case, it will add both the public and protected routes.
  """

  defmacro __using__(_opts \\ []) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Coherence Router macro.

  Use this macro to define the various Coherence Routes.

  ## Examples:

      # Routes that don't require authentication
      scope "/" do
        pipe_through :browser
        coherence_routes
      end

      # Routes that require authentication
      scope "/" do
        pipe_through :protected
        coherence_routes :protected
      end
  """
  defmacro coherence_routes(mode \\ [], opts \\ []) do
    {mode, _opts} = case mode do
      :private ->
        IO.warn "coherence_routes :private has been deprecated. Please use :protected instead."
        {:protected, opts}
      mode when is_atom(mode) -> {mode, opts}
      []                      -> {:public, []}
      opts when is_list(opts) -> {:all, opts}
    end
    quote location: :keep do
      mode = unquote(mode)

      if mode == :public && Module.get_attribute(__MODULE__, :__COHERENCE_PROTECTED__) do
        raise "Protected routes must follow public routes. Please move 'coherence_routes :protected' below 'coherence_routes'."
      end
      if mode == :protected do
        Module.put_attribute __MODULE__, :__COHERENCE_PROTECTED__, true
      end

      if mode == :all or mode == :public do
        Enum.each([:new, :create], fn(action) ->
          if Coherence.Config.has_action?(:authenticatable, action) do
            resources "/sessions", Coherence.SessionController, only: [action]
          end
        end)
        if Coherence.Config.has_action?(:registerable, :new) do
          get "/registrations/new", Coherence.RegistrationController, :new
        end
        if Coherence.Config.has_action?(:registerable, :create) do
          post "/registrations", Coherence.RegistrationController, :create
        end
        Enum.each([:new, :create, :edit, :update], fn(action) ->
          if Coherence.Config.has_action?(:recoverable, action) do
            resources "/passwords", Coherence.PasswordController, only: [action]
          end
        end)
        Enum.each([:edit, :new, :create], fn(action) ->
          if Coherence.Config.has_action?(:confirmable, action) do
            resources "/confirmations", Coherence.ConfirmationController, only: [action]
          end
        end)
        Enum.each([:new, :create, :edit], fn(action) ->
          if Coherence.Config.has_action?(:unlockable_with_token, action) do
            resources "/unlocks", Coherence.UnlockController, only: [action]
          end
        end)
        if Coherence.Config.has_action?(:invitable, :edit) do
          resources "/invitations", Coherence.InvitationController, only: [:edit]
        end
        if Coherence.Config.has_action?(:invitable, :create_user) do
          post "/invitations/create", Coherence.InvitationController, :create_user
        end
      end
      if mode == :all or mode == :protected do
        if Coherence.Config.has_action?(:invitable, :new) do
          resources "/invitations", Coherence.InvitationController, only: [:new]
        end
        if Coherence.Config.has_action?(:invitable, :create) do
          resources "/invitations", Coherence.InvitationController, only: [:create]
        end
        if Coherence.Config.has_action?(:invitable, :resend) do
          get "/invitations/:id/resend", Coherence.InvitationController, :resend
        end
        if Coherence.Config.has_action?(:authenticatable, :delete) do
          delete "/sessions", Coherence.SessionController, :delete
        end
        if Coherence.Config.has_action?(:registerable, :show) do
          get "/registrations", Coherence.RegistrationController, :show
        end
        if Coherence.Config.has_action?(:registerable, :update) do
          put "/registrations", Coherence.RegistrationController, :update
          patch "/registrations", Coherence.RegistrationController, :update
        end
        if Coherence.Config.has_action?(:registerable, :edit) do
          get "/registrations/edit", Coherence.RegistrationController, :edit
        end
        if Coherence.Config.has_action?(:registerable, :delete) do
          delete "/registrations", Coherence.RegistrationController, :delete
        end
      end
    end
  end
end
