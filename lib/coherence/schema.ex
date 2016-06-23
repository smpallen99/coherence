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
        |> set_password(params)
      end

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

  defmacro coherence_schema do
    quote do
      field :encrypted_password, :string
      field :password, :string, virtual: true
      field :password_confirmation, :string, virtual: true
    end
  end

  def coherence_fields, do: ~w(encrypted_password password password_confirmation)
end
