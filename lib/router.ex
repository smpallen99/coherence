defmodule Coherence.Router do

  defmacro __using__(opts \\ []) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro coherence_routes(opts \\ []) do
    quote do
      opts = unquote(opts)
      sign_in = Keyword.get(opts, :sign_in, "/sign_in")
      sign_out = Keyword.get(opts, :sign_in, "/sign_out")

      resources "/sessions", Coherence.SessionController, only: [:new, :create, :delete]
      resources "/registrations", Coherence.RegistrationController, only: [:new, :create, :edit, :update, :delete]
      resources "/passwords", Coherence.PasswordController, only: [:new, :create, :edit, :update, :delete]
      resources "/confirmations", Coherence.ConfirmationController, only: [:edit]
      resources "/invitations", Coherence.InvitationController, only: [:new, :create, :edit]
      post "/invitations/create", Coherence.InvitationController, :create_user
      resources "/unlocks", Coherence.UnlockController, only: [:new, :create, :edit]
    end
  end

end
