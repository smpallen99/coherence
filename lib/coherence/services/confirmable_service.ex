defmodule Coherence.ConfirmableService do
  @moduledoc """
  Confirmable allows users to confirm a new account.

  When enabled, newly created accounts are emailed send a confirmation
  email with a confirmation link. Clicking on the confirmation link enables
  the account.

  Access to the account is disabled until the account is enabled, unless the
  the `allow_unconfirmed_access_for` option is configured. If the account is
  not confirmed before the `confirmation_token_expire_days` configuration days
  expires, a new confirmation must be sent.

  Confirmable adds the following database columns to the user model:

  * :confirmation_token - a unique token required to confirm the account
  * :confirmed_at - time and date the account was confirmed
  * :confirmation_sent_at - the time and date the confirmation token was created

  The following configuration is used to customize confirmable behavior:

  * :confirmation_token_expire_days  - number days to allow confirmation. default 5 days
  * :allow_unconfirmed_access_for - number of days to allow login access to the account before confirmation.
  default 0 (disabled)
  """

  use Coherence.Config
  use CoherenceWeb, :service

  import Coherence.Controller

  alias Coherence.{Messages, Schemas}

  defmacro __using__(opts \\ []) do
    quote do
      # import unquote(__MODULE__)
      use Coherence.Config

      alias Coherence.Schemas

      def confirmable? do
        Config.has_option(:confirmable) and
          Keyword.get(unquote(opts), :confirmable, true)
      end

      if Config.has_option(:confirmable) and
            Keyword.get(unquote(opts), :confirmable, true) do

        @doc """
        Checks if the user has been confirmed.

        Returns true if confirmed, false otherwise
        """
        def confirmed?(user) do
          !!user.confirmed_at
        end

        @doc """
        Confirm a user account.

        Adds the `:confirmed_at` datetime field on the user model.

        Returns a changeset ready for Repo.update
        """
        def confirm(user) do
          Schemas.change_user(user, %{confirmed_at: NaiveDateTime.utc_now(), confirmation_token: nil})
        end

        @doc """
        Confirm a user account.

        Adds the `:confirmed_at` datetime field on the user model.

        deprecated! Please use Coherence.ControllerHelpers.unlock!/1.
        """
        def confirm!(user) do
          IO.warn "#{inspect Config.user_schema}.confirm!/1 has been deprecated. Please use Coherence.ControllerHelpers.confirm!/1 instead."
          changeset = Schemas.change_user(user, %{confirmed_at: NaiveDateTime.utc_now(), confirmation_token: nil})
          if confirmed? user do
            changeset = Ecto.Changeset.add_error changeset, :confirmed_at, Messages.backend().already_confirmed()
            {:error, changeset}
          else
            Config.repo.update changeset
          end
        end
      end
    end
  end


  @doc """
  Confirm a user account.

  Adds the `:confirmed_at` datetime field on the user model.

  deprecated! Please use Coherence.ControllerHelpers.unlock!/1.
  """
  @spec confirm(Ecto.Schema.t) :: Ecto.Changeset.t
  def confirm(user) do
    Schemas.change_user(user, %{confirmed_at: NaiveDateTime.utc_now(), confirmation_token: nil})
  end

  @doc """
  Confirm a user account.

  Adds the `:confirmed_at` datetime field on the user model.

  deprecated! Please use Coherence.ControllerHelpers.unlock!/1.
  """
  @spec confirm!(Ecto.Schema.t) :: Ecto.Changeset.t | {:error, Ecto.Changeset.t}
  def confirm!(user) do
    changeset = Schemas.change_user(user, %{confirmed_at: NaiveDateTime.utc_now(), confirmation_token: nil})

    if confirmed? user do
      changeset = Ecto.Changeset.add_error changeset, :confirmed_at, Messages.backend().already_confirmed()
      {:error, changeset}
    else
      Schemas.update changeset
    end
  end


  @doc """
  Checks if the user has been confirmed.

  Returns true if confirmed, false otherwise
  """
  @spec confirmed?(Ecto.Schema.t) :: boolean
  def confirmed?(user) do
    for_option true, fn ->
      !!user.confirmed_at
    end
  end

  @doc """
  Checks if the confirmation token has expired.

  Returns true when the confirmation has expired.
  """
  @spec expired?(Ecto.Schema.t) :: boolean
  def expired?(user) do
    for_option fn ->
      expired?(user.confirmation_sent_at, days: Config.confirmation_token_expire_days)
    end
  end

  @doc """
  Checks if the user can access the account before confirmation.

  Returns true if the unconfirmed access has not expired.
  """
  @spec unconfirmed_access?(Ecto.Schema.t) :: boolean
  def unconfirmed_access?(user) do
    for_option fn ->
      case Config.allow_unconfirmed_access_for do
        0 -> false
        days -> not expired?(user.confirmation_sent_at, days: days)
      end
    end
  end

  defp for_option(other \\ false, fun) do
    if Config.has_option(:confirmable) do
      fun.()
    else
      other
    end
  end

end
