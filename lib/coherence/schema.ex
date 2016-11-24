defmodule Coherence.Schema do
  @moduledoc """
  Add Coherence support to a User schema module.

  Add `use Coherence.Schema, opts \\ []` to your User module to add a number of
  Module functions and helpers.

  The optional `opt` parameter can be used to disable options enabled in the
  global configuration by passing `option: false`

  For example,

      defmodule MyProject.User do
        use MyProject.Web, :model
        use Coherence.Schema, invitable: false


  The following functions are added regardless of the options configured:

  * `authenticatable?/0` - Returns true if the option is configured.
  * `registerable?/0` - Returns true if the option is configured.
  * `confirmable?/0` - Returns true if the option is configured.
  * `trackable?/0` - Returns true if the option is configured.
  * `recoverable?/0` - Returns true if the option is configured.
  * `lockable?/0` - Returns true if the option is configured.
  * `invitable?/0` - Returns true if the option is configured.
  * `unlockable_with_token?/0` - Returns true if the option is configured.

  The following functions are available when `authenticatable?/0` returns true:

  * `checkpw/2` - Validate password.
  * `encrypt_password/1` - encrypted a password using `Comeonin.Bcrypt.hashpwsalt`
  * `validate_coherence/2` - run the coherence password validations.
  * `validate_password/2` - Used by `validate_coherence for password validation`

  The following functions are available when `confirmable?/0` returns true.

  * `confirmed?/1` - Has the given user been confirmed?
  * `confirm/1` - Return a changeset to confirm the given user

  The following functions are available when `lockable?/0` returns true.

  * `locked?/1` - Is the given user locked?
  * `lock/1` - Return a changeset to lock the given user
  * `unlock/1` - Return a changeset to unlock the given user

  The `coherence_schema/1` macro is used to add the configured schema fields to the User models schema.

  The `coherence_fields/0` function is used to return the validation fields appropriate for the selected options.


  ## Examples:

  The following is an example User module when the :authenticatable is used:

      defmodule MyProject.User do
        use MyProject.Web, :model
        use Coherence.Schema

        schema "users" do
          field :name, :string
          field :email, :string
          coherence_schema

          timestamps
        end

        @required_fields ~w(name email)
        @optional_fields ~w() ++ coherence_fields

        def changeset(model, params \\ %{}) do
          model
          |> cast(params, @required_fields, @optional_fields)
          |> unique_constraint(:email)
          |> validate_coherence(params)
        end
      end

  """
  use Coherence.Config

  defmacro __using__(opts \\ []) do
    quote do
      import unquote(__MODULE__)
      import Ecto.Changeset
      use Coherence.Config
      require Logger
      alias Coherence.Schema.{Confirmable}

      use Confirmable, unquote(opts)

      def authenticatable? do
        Coherence.Config.has_option(:authenticatable) and
          Keyword.get(unquote(opts), :authenticatable, true)
      end

      def registerable? do
        Coherence.Config.has_option(:registerable) and
          Keyword.get(unquote(opts), :registerable, true)
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

      def invitable? do
        Coherence.Config.has_option(:invitable) and
          Keyword.get(unquote(opts), :invitable, true)
      end

      def unlockable_with_token? do
        Coherence.Config.has_option(:unlockable_with_token) and
          Keyword.get(unquote(opts), :unlockable_with_token, true)
      end

      def rememberable? do
        Coherence.Config.has_option(:rememberable) and
          Keyword.get(unquote(opts), :rememberable, true)
      end

      if  Coherence.Config.has_option(:lockable) and
            Keyword.get(unquote(opts), :lockable, true) do

        @doc """
        Checks if the user is locked.

        Returns true if locked, false otherwise
        """
        def locked?(user) do
          !!user.locked_at and
            !Coherence.ControllerHelpers.expired?(user.locked_at,
                minutes: Config.unlock_timeout_minutes)
        end

        @doc """
        Unlock a user account.

        Clears the `:locked_at` field on the user model.

        Returns a changeset ready for Repo.update
        """
        def unlock(user) do
          Config.user_schema.changeset(user, %{locked_at: nil, unlock_token: nil, failed_attempts: 0})
        end

        @doc """
        Unlock a user account.

        Clears the `:locked_at` field on the user model.

        deprecated! Please use Coherence.ControllerHelpers.unlock!/1.
        """
        def unlock!(user) do
          IO.warn "#{inspect Config.user_schema}.unlock!/1 has been deprecated. Please use Coherence.ControllerHelpers.unlock!/1 instead."
          changeset = unlock user
          if locked?(user) do
            changeset
            |> Config.repo.update
          else
            changeset = Ecto.Changeset.add_error changeset, :locked_at, "not locked"
            {:error, changeset}
          end
        end

        @doc """
        Lock a use account.

        Sets the `:locked_at` field on the user model to the current date and time unless
        provided a value for the optional parameter.

        You can provide a date in the future to override the configured lock expiry time. You
        can set this data far in the future to do a pseudo permanent lock.

        Returns a changeset ready for Repo.update
        """
        def lock(user, locked_at \\ Ecto.DateTime.utc) do
          Config.user_schema.changeset(user, %{locked_at: locked_at})
        end

        @doc """
        Lock a use account.

        Sets the `:locked_at` field on the user model to the current date and time unless
        provided a value for the optional parameter.

        You can provide a date in the future to override the configured lock expiry time. You
        can set this data far in the future to do a pseudo permanent lock.

        deprecated! Please use Coherence.ControllerHelpers.lock!/1.
        """

        def lock!(user, locked_at \\ Ecto.DateTime.utc) do
          IO.warn "#{inspect Config.user_schema}.lock!/1 has been deprecated. Please use Coherence.ControllerHelpers.lock!/1 instead."
          changeset = Config.user_schema.changeset(user, %{locked_at: locked_at})
          unless locked?(user) do
            changeset
            |> Config.repo.update
          else
            changeset = Ecto.Changeset.add_error changeset, :locked_at, "already locked"
            {:error, changeset}
          end
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
          if is_nil(Map.get(changeset.data, Config.password_hash)) and is_nil(changeset.changes[:password]) do
            changeset
            |> add_error(:password, "can't be blank")
          else
            changeset
            |> validate_confirmation(:password)
            |> set_password(params)
          end
        end

        defp set_password(changeset, _params) do
          if changeset.valid? and not is_nil(changeset.changes[:password]) do
            put_change changeset, Config.password_hash,
              encrypt_password(changeset.changes[:password])
          else
            changeset
          end
        end
      else
        def validate_coherence(changeset, _params), do: changeset
      end
    end
  end

  @doc """
  Get list of migration schema fields for each option.

  Helper function to return a keyword list of the migration fields for each
  of the supported options.

  TODO: Does this really belong here? Should it not be in a migration support
  module?
  """

  def schema_fields, do: [
    authenticatable: [
      "# authenticatable",
      "add :#{Config.password_hash}, :string",
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
      "add :locked_at, :datetime",
    ],
    unlockable_with_token: [
      "# unlockable_with_token",
      "add :unlock_token, :string",
    ],
    confirmable: [
      "# confirmable",
      "add :confirmation_token, :string",
      "add :confirmed_at, :datetime",
      "add :confirmation_sent_at, :datetime"
    ]
  ]

  @doc """
  Add configure schema fields.

  Adds the schema fields to the schema block for the options selected.
  Only the fields for configured options are added.

  For example, for `Coherence.Config.opts == [:authenticatable, :recoverable]`
  `coherence_schema` used in the following context:

      defmodule MyProject.User do
        use MyProject.Web, :model
        use Coherence.Schema

        schema "users" do
          field :name, :string
          field :email, :string
          coherence_schema

          timestamps
        end

  Will compile a schema to the following:

      defmodule MyProject.User do
        use MyProject.Web, :model
        use Coherence.Schema

        schema "users" do
          field :name, :string
          field :email, :string

          # authenticatable
          field :password_hash, :string
          field :password, :string, virtual: true
          field :password_confirmation, :string, virtual: true

          # recoverable
          field :reset_password_token, :string
          field :reset_password_sent_at, Ecto.DateTime

          timestamps
        end

  """
  defmacro coherence_schema do
    quote do
      if Coherence.Config.has_option(:authenticatable) do
        field Config.password_hash, :string
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
        field :locked_at, Ecto.DateTime
      end
      if Coherence.Config.has_option(:unlockable_with_token) do
        field :unlock_token, :string
      end
      if Coherence.Config.has_option(:confirmable) do
        field :confirmation_token, :string
        field :confirmed_at, Ecto.DateTime
        field :confirmation_sent_at, Ecto.DateTime
        # field :unconfirmed_email, :string
      end
    end
  end

  @optional_fields %{
    authenticatable: ~w(#{Config.password_hash} password password_confirmation),
    recoverable: ~w(reset_password_token reset_password_sent_at),
    rememberable: ~w(remember_created_at),
    trackable: ~w(sign_in_count current_sign_in_at last_sign_in_at current_sign_in_ip last_sign_in_ip),
    lockable: ~w(locked_at failed_attempts),
    unlockable_with_token: ~w(unlock_token),
    confirmable: ~w(confirmation_token confirmed_at confirmation_sent_at)
  }

  @doc """
  Get a list of the configured database fields.

  Returns a list of fields that can be appended to your @option_fields used
  in your models changeset cast.

  For example, for `Coherence.Config.opts == [:authenticatable, :recoverable]`
  `coherence_fiels/0` will return:

      ~w(password_hash password password_confirmation reset_password_token reset_password_sent_at)
  """
  def coherence_fields do
    []
    |> options_fields(:authenticatable)
    |> options_fields(:recoverable)
    |> options_fields(:rememberable)
    |> options_fields(:trackable)
    |> options_fields(:lockable)
    |> options_fields(:unlockable_with_token)
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
