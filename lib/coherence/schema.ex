defmodule Coherence.Schema do

  defmacro __using__(opts \\ []) do
    quote do
      import unquote(__MODULE__)
      import Ecto.Changeset
      alias Coherence.Config

      def authenticatable? do
        Coherence.Config.has_option(:authenticatable) and
          Keyword.get(unquote(opts), :authenticatable, true)
      end

      def registerable? do
        Coherence.Config.has_option(:registerable) and
          Keyword.get(unquote(opts), :registerable, true)
      end

      def confirmable? do
        Coherence.Config.has_option(:confirmable) and
          Keyword.get(unquote(opts), :confirmable, true)
      end

      def trackable? do
        Coherence.Config.has_option(:trackable) and
          Keyword.get(unquote(opts), :trackable, true)
      end

      def recoverable? do
        Coherence.Config.has_option(:recoverable) and
          Keyword.get(unquote(opts), :recoverable, true)
      end

      def lockable? do
        Coherence.Config.has_option(:lockable) and
          Keyword.get(unquote(opts), :lockable, true)
      end

      if  Coherence.Config.has_option(:confirmable) and
            Keyword.get(unquote(opts), :confirmable, true) do
        def confirmed?(user) do
          !!user.confirmed_at
        end

        def confirm!(user) do
          Config.user_schema.changeset(user, %{confirmed_at: Ecto.DateTime.utc, confirmation_token: nil})
          |> Config.repo.update
        end
      end

      if  Coherence.Config.has_option(:lockable) and
            Keyword.get(unquote(opts), :lockable, true) do

        def locked?(user) do
          !!user.locked_at and
            !Coherence.ControllerHelpers.expired?(user.locked_at,
                minutes: Config.unlock_timeout_minutes)
        end

        def unlock!(user) do
          Config.user_schema.changeset(user, %{locked_at: nil, unlock_token: nil})
          |> Config.repo.update
        end
      end

      if  Coherence.Config.has_option(:authenticatable) and
            Keyword.get(unquote(opts), :authenticatable, true) do

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

        def validate_coherence(changeset, params) do
          changeset
          |> validate_length(:password, min: 4)
          |> validate_password(params)
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
  end

  def schema_fields, do: [
    authenticatable: [
      "# authenticatable",
      "add :encrypted_password, :string",
    ],
    recoverable: [
      "# recoverable",
      "add :reset_password_token, :string",
      "add :reset_password_sent_at, :datetime"
    ],
    rememberable: [
      "# rememberable",
      "add :remember_created_at, :datetime"
    ],
    trackable: [
      "# trackable",
      "add :sign_in_count, :integer, default: 0",
      "add :current_sign_in_at, :datetime",
      "add :last_sign_in_at, :datetime",
      "add :current_sign_in_ip, :string",
      "add :last_sign_in_ip, :string"
    ],
    lockable: [
      "# lockable",
      "add :failed_attempts, :integer, default: 0",
      "add :unlock_token, :string",
      "add :locked_at, :datetime",
    ],
    confirmable: [
      "# confirmable",
      "add :confirmation_token, :string",
      "add :confirmed_at, :datetime",
      "add :confirmation_send_at, :datetime"
    ]
  ]

  defmacro coherence_schema do
    quote do
      if Coherence.Config.has_option(:authenticatable) do
        field :encrypted_password, :string
        field :password, :string, virtual: true
        field :password_confirmation, :string, virtual: true
      end

      if Coherence.Config.has_option(:recoverable) do
        field :reset_password_token, :string
        field :reset_password_sent_at, Ecto.DateTime
      end
      if Coherence.Config.has_option(:rememberable) do
        field :remember_created_at, Ecto.DateTime
      end
      if Coherence.Config.has_option(:trackable) do
        field :sign_in_count, :integer, default: 0
        field :current_sign_in_at, Ecto.DateTime
        field :last_sign_in_at, Ecto.DateTime
        field :current_sign_in_ip, :string
        field :last_sign_in_ip, :string
      end
      if Coherence.Config.has_option(:lockable) do
        field :failed_attempts, :integer, default: 0
        field :unlock_token, :string
        field :locked_at, Ecto.DateTime
      end
      if Coherence.Config.has_option(:confirmable) do
        field :confirmation_token, :string
        field :confirmed_at, Ecto.DateTime
        field :confirmation_send_at, Ecto.DateTime
        # field :unconfirmed_email, :string
      end
    end
  end

  @optional_fields %{
    authenticatable: ~w(encrypted_password password password_confirmation),
    recoverable: ~w(reset_password_token reset_password_sent_at),
    rememberable: ~w(remember_created_at),
    trackable: ~w(sign_in_count current_sign_in_at last_sign_in_at current_sign_in_ip last_sign_in_ip failed_attempts),
    lockable: ~w(unlock_token locked_at),
    confirmable: ~w(confirmation_token confirmed_at confirmation_send_at)
  }

  def coherence_fields do
    []
    |> options_fields(:authenticatable)
    |> options_fields(:recoverable)
    |> options_fields(:rememberable)
    |> options_fields(:trackable)
    |> options_fields(:lockable)
    |> options_fields(:confirmable)
  end

  defp options_fields(fields, key) do
    if Coherence.Config.has_option(key) do
      fields ++ @optional_fields[key]
    else
      fields
    end
  end
end
