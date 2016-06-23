defmodule Coherence.Schema do

  defmacro __using__(opts \\ []) do
    quote do
      import unquote(__MODULE__)
      import Ecto.Changeset

      def checkpw(password, encrypted) do
        try do
          Comeonin.Bcrypt.checkpw(password, encrypted)
        rescue
          _ -> false
        end
      end

      def encrypt_password(password) do
        Comeonin.Bcrypt.hashpwsalt(password)
      end

      def validate_password(changeset, params) do
        changeset
        |> validate_confirmation(:password)
        # |> validate_password_match(params)
        |> set_password(params)
      end
      # defp validate_password_match(changeset, _params) do
      #   validate_change(changeset, :password, fn(:password, value) ->
      #     if value == changeset.changes[:password_confirmation], do: [],
      #       else: [{:password, {:must_match, :password_confirmation}}]
      #   end)
      # end
      defp set_password(changeset, _params) do
        if changeset.valid? and not is_nil(changeset.changes[:password]) do
          put_change changeset, :encrypted_password,
            encrypt_password(changeset.changes[:password])
        else
          changeset
        end
      end
    end
  end


end
