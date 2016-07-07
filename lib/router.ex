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
          plug Coherence.Authentication.Session, db_model: MyProject.User
        end

        pipeline :public do
          plug :accepts, ["html"]
          # ...
          plug Coherence.Authentication.Session, db_model: MyProject.User, login: false  # Add this
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
        get "/", Admin1.PageController, :index
      end

      # Routes that require authentication
      scope "/" do
        pipe_through :browser
        coherence_routes :private
      end
  """
  defmacro coherence_routes(mode, opts \\ [])
  defmacro coherence_routes(:public, _opts) do
    quote do
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
        resources "/confirmations", Coherence.ConfirmationController, only: [:edit]
      end
      if Coherence.Config.has_option(:unlockable_with_token) do
        resources "/unlocks", Coherence.UnlockController, only: [:new, :create, :edit]
      end
    end
  end
  defmacro coherence_routes(:private, _opts) do
    quote do
      if Coherence.Config.has_option(:invitable) do
        resources "/invitations", Coherence.InvitationController, only: [:new, :create, :edit]
        post "/invitations/create", Coherence.InvitationController, :create_user
      end
      if Coherence.Config.has_option(:authenticatable) do
        resources "/sessions", Coherence.SessionController, only: [:delete]
      end
    end
  end

end
