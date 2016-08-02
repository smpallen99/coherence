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
          plug Coherence.Authentication.Session, login: true
        end

        pipeline :public do
          plug :accepts, ["html"]
          # ...
          plug Coherence.Authentication.Session
        end

        scope "/" do
          pipe_through :public
          coherence_routes :public
        end

        scope "/" do
          pipe_through :browser
          coherence_routes :private
        end
        # ...
      end

  Alternatively, you may want to use the login plug in individual controllers. In
  this case, you can have one pipeline, one scope and call `coherence_routes` without
  any parameters. In this case, it will add both the public and private routes.
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
        pipe_through :public
        coherence_routes :public
      end

      # Routes that require authentication
      scope "/" do
        pipe_through :browser
        coherence_routes :private
      end
  """
  defmacro coherence_routes(mode \\ [], opts \\ []) do
    {mode, _opts} = case mode do
      mode when is_atom(mode) -> {mode, opts}
      []                      -> {:all, []}
      opts when is_list(opts) -> {:all, opts}
    end
    quote do
      mode = unquote(mode)
      if mode == :all or mode == :public do
        if Coherence.Config.has_option(:authenticatable) do
          resources "/sessions", Coherence.SessionController, only: [:new, :create]
        end
        if Coherence.Config.has_option(:registerable) do
          resources "/registrations", Coherence.RegistrationController, only: [:new, :create, :edit, :update, :delete]
        end
        if Coherence.Config.has_option(:recoverable) do
          resources "/passwords", Coherence.PasswordController, only: [:new, :create, :edit, :update, :delete]
        end
        if Coherence.Config.has_option(:confirmable) do
          resources "/confirmations", Coherence.ConfirmationController, only: [:edit, :new, :create]
        end
        if Coherence.Config.has_option(:unlockable_with_token) do
          resources "/unlocks", Coherence.UnlockController, only: [:new, :create, :edit]
        end
      end
      if mode == :all or mode == :private do
        if Coherence.Config.has_option(:invitable) do
          resources "/invitations", Coherence.InvitationController, only: [:new, :create, :edit]
          post "/invitations/create", Coherence.InvitationController, :create_user
          get "/invitations/:id/resend", Coherence.InvitationController, :resend
        end
        if Coherence.Config.has_option(:authenticatable) do
          resources "/sessions", Coherence.SessionController, only: [:delete]
        end
      end
    end
  end
end
