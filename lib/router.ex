defmodule Coherence.Router do

  defmacro __using__(opts \\ []) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro coherence_routes(opts \\ []) do
    quote do
      alias Coherence.{SessionController, RegistrationController, PasswordController}
      opts = unquote(opts)
      sign_in = Keyword.get(opts, :sign_in, "/sign_in")
      sign_out = Keyword.get(opts, :sign_in, "/sign_out")

      resources "/sessions", SessionController, only: [:new, :create, :delete]
      resources "/registrations", RegistrationController, only: [:new, :create, :edit, :update, :delete]
      resources "/passwords", PasswordController, only: [:new, :create, :edit, :update, :delete]
      # get sign_in, SessionController, :new
      # post sign_in, SessionController, :create
      # patch sign_out, SessionController, :delete
      # delete sign_out, SessionController, :delete
      # patch sign_out, SessionController, :destroy
      # delete sign_out, SessionController, :destroy
    end
  end

end
