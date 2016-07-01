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
      if Coherence.Config.has_option(:resettable) do
        field :reset_password_token, :string
        field :reset_password_sent_at, Ecto.DateTime
      end
      if Coherence.Config.has_option(:rememberable) do
        field :remember_created_at, Ecto.DateTime
      end
      if Coherence.Config.has_option(:trackable) do
        field :sign_in_count, :integer
        field :current_sign_in_at, Ecto.DateTime
        field :last_sign_in_at, Ecto.DateTime
        field :current_sign_in_ip, :string
        field :last_sign_in_ip, :string
        field :failed_attempts, :integer
      end
      if Coherence.Config.has_option(:lockable) do
        field :unlock_token, :string
        field :locked_at, Ecto.DateTime
      end
    end
  end

  @base_fields ~w(encrypted_password password password_confirmation)
  @optional_fields %{
    resettable: ~w(reset_password_token reset_password_sent_at),
    rememberable: ~w(remember_created_at),
    trackable: ~w(sign_in_count current_sign_in_at last_sign_in_at current_sign_in_ip last_sign_in_ip failed_attempts),
    lockable: ~w(unlock_token locked_at)
  }

  def coherence_fields do
    @base_fields
    |> options_fields(:resettable)
    |> options_fields(:rememberable)
    |> options_fields(:trackable)
    |> options_fields(:lockable)
  end

  defp options_fields(fields, key) do
    if Coherence.Config.has_option(key) do
      fields ++ @optional_fields[key]
    else
      fields
    end
  end
end
