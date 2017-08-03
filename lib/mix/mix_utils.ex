defmodule Coherence.Mix.Utils do
  @moduledoc false

  @dialyzer [
    {:nowarn_function, raise_option_errors: 1},
  ]

  @spec rm_dir!(String.t) :: any
  def rm_dir!(dir) do
    if File.dir? dir do
      File.rm_rf dir
    end
  end

  @spec rm!(String.t) :: any
  def rm!(file) do
    if File.exists? file do
      File.rm! file
    end
  end

  @spec raise_option_errors([:atom]) :: String.t
  def raise_option_errors(list) do
    list = Enum.map(list, fn option ->
      "--" <> Atom.to_string(option) |> String.replace("_", "-")
    end)

    list = Enum.join(list, ", ")

    Mix.raise """
    The following option(s) are not supported:
        #{inspect list}
    """
  end

  @spec verify_args!([String.t] | [], [String.t] | []) :: String.t | nil
  def verify_args!(parsed, unknown) do
    unless parsed == [] do
      opts = Enum.join parsed, ", "
      Mix.raise """
      Invalid argument(s) #{opts}
      """
    end
    unless unknown == [] do
      opts =
        unknown
        |> Enum.map(&(elem(&1,0)))
        |> Enum.join(", ")
      Mix.raise """
      Invalid argument(s) #{opts}
      """
    end
  end

  @doc """
  Get list of migration schema fields for each option.

  Helper function to return a keyword list of the migration fields for each
  of the supported options.

  TODO: Does this really belong here? Should it not be in a migration support
  module?
  """

  def schema_fields(config) do
    active_field =
      if config.user_active_field? do
        ["add :active, :boolean, null: false, default: true"]
      else
        []
      end
    [
      authenticatable: [
        "# authenticatable",
        "add :password_hash, :string",
      ] ++ active_field,
      recoverable: [
        "# recoverable",
        "add :reset_password_token, :string",
        "add :reset_password_sent_at, :utc_datetime"
      ],
      rememberable: [
        "# rememberable",
        "add :remember_created_at, :utc_datetime"
      ],
      trackable: [
        "# trackable",
        "add :sign_in_count, :integer, default: 0",
        "add :current_sign_in_at, :utc_datetime",
        "add :last_sign_in_at, :utc_datetime",
        "add :current_sign_in_ip, :string",
        "add :last_sign_in_ip, :string"
      ],
      lockable: [
        "# lockable",
        "add :failed_attempts, :integer, default: 0",
        "add :locked_at, :utc_datetime",
      ],
      unlockable_with_token: [
        "# unlockable_with_token",
        "add :unlock_token, :string",
      ],
      confirmable: [
        "# confirmable",
        "add :confirmation_token, :string",
        "add :confirmed_at, :utc_datetime",
        "add :confirmation_sent_at, :utc_datetime"
      ]
    ]
  end

  def controller_files, do: [
    confirmable: "confirmation_controller.ex",
    invitable: "invitation_controller.ex",
    recoverable: "password_controller.ex",
    registerable: "registration_controller.ex",
    authenticatable: "session_controller.ex",
    unlockable_with_token: "unlock_controller.ex"
  ]

end
