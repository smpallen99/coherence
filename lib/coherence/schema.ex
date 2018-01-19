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
  * `trackable_table?/0` - Returns true if the option is configured.
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

        def changeset(model, params, :password) do
          model
          |> cast(params, ~w(password password_confirmation reset_password_token reset_password_sent_at))
          |> validate_coherence_password_reset(params)
        end
      end

  """
  use Coherence.Config

  defmacro __using__(opts \\ []) do
    quote do
      import unquote(__MODULE__)
      import Ecto.Changeset
      alias Coherence.Messages

      alias Coherence.{ConfirmableService}

      use Coherence.Config
      use ConfirmableService, unquote(opts)

      require Logger

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

      def trackable_table? do
        Coherence.Config.has_option(:trackable_table) and
          Keyword.get(unquote(opts), :trackable_table, true)
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
            !Coherence.Controller.expired?(user.locked_at,
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
            Config.repo.update changeset
          else
            changeset = Ecto.Changeset.add_error changeset, :locked_at, Messages.backend().not_locked()
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
        def lock(user, locked_at \\ NaiveDateTime.utc_now()) do
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

        def lock!(user, locked_at \\ NaiveDateTime.utc_now()) do
          IO.warn "#{inspect Config.user_schema}.lock!/1 has been deprecated. Please use Coherence.ControllerHelpers.lock!/1 instead."
          changeset = Config.user_schema.changeset(user, %{locked_at: locked_at})
          if locked?(user) do
            changeset = Ecto.Changeset.add_error changeset, :locked_at, Messages.backend().already_locked()
            {:error, changeset}
          else
            Config.repo.update changeset
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
          |> validate_length(:password, min: Config.minimum_password_length)
          |> validate_current_password(params)
          |> validate_password(params)
        end

        def validate_coherence_password_reset(changeset, params) do
          changeset
          |> validate_length(:password, min: Config.minimum_password_length)
          |> validate_password(params)
        end

        def validate_current_password(changeset, params) do
          current_password = params[:current_password] || params["current_password"]
          # current_password_required? = Config.require_current_password and
          #   (not is_nil(changeset.data.id)) and Map.has_key?(changeset.changes, :password)

          # with true <- current_password_required?,
          #      true <- if(current_password, do: true, else: {:error, "can't be blank"}),
          #      true <-
          #       if(checkpw(current_password, Map.get(changeset.data, Config.password_hash), do: true, else: "invalid current password") do
          if Config.require_current_password and (not is_nil(changeset.data.id)) and Map.has_key?(changeset.changes, :password) do
            if is_nil(current_password) do
              add_error(changeset, :current_password, Messages.backend().cant_be_blank())
            else
              if not checkpw(current_password, Map.get(changeset.data, Config.password_hash)) do
                add_error(changeset, :current_password, Messages.backend().invalid_current_password())
              else
                changeset
              end
            end
          else
            changeset
          end
        end

        def validate_password(changeset, params) do
          if is_nil(Map.get(changeset.data, Config.password_hash)) and is_nil(changeset.changes[:password]) do
            add_error(changeset, :password, Messages.backend().cant_be_blank())
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
          field :active, :boolean, default: true

          # authenticatable
          field :password_hash, :string
          field :password, :string, virtual: true
          field :password_confirmation, :string, virtual: true

          # recoverable
          field :reset_password_token, :string
          field :reset_password_sent_at, NaiveDateTime

          timestamps
        end

  """
  defmacro coherence_schema do
    quote do
      if Coherence.Config.has_option(:authenticatable) do
        field Config.password_hash, :string
        field :current_password, :string, virtual: true
        field :password, :string, virtual: true
        field :password_confirmation, :string, virtual: true
        if Coherence.Config.user_active_field do
          field :active, :boolean, default: true
        end
      end

      if Coherence.Config.has_option(:recoverable) do
        field :reset_password_token, :string
        field :reset_password_sent_at, :naive_datetime
      end
      if Coherence.Config.has_option(:rememberable) do
        field :remember_created_at, :naive_datetime
      end
      if Coherence.Config.has_option(:trackable) do
        field :sign_in_count, :integer, default: 0
        field :current_sign_in_at, :naive_datetime
        field :last_sign_in_at, :naive_datetime
        field :current_sign_in_ip, :string
        field :last_sign_in_ip, :string
      end
      if Coherence.Config.has_option(:trackable_table) do
        has_many :trackables, Module.concat(Config.module, Coherence.Trackable)
      end
      if Coherence.Config.has_option(:lockable) do
        field :failed_attempts, :integer, default: 0
        field :locked_at, :naive_datetime
      end
      if Coherence.Config.has_option(:unlockable_with_token) do
        field :unlock_token, :string
      end
      if Coherence.Config.has_option(:confirmable) do
        field :confirmation_token, :string
        field :confirmed_at, :naive_datetime
        field :confirmation_sent_at, :naive_datetime
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
  `coherence_fields/0` will return:

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

  defp options_fields(fields, :authenticatable = key) do
    fields ++
      cond do
        not Coherence.Config.has_option(key) ->
          []
        Coherence.Config.user_active_field ->
          ["active" | @optional_fields[key]]
        true ->
          @optional_fields[key]
      end
  end
  defp options_fields(fields, key) do
    if Coherence.Config.has_option(key) do
      fields ++ @optional_fields[key]
    else
      fields
    end
  end
end
