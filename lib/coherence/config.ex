defmodule Coherence.Config do
  @moduledoc """
  Coherence Configuration Module.

  Provides a small wrapper around `Application.get_env :coherence`, providing an accessor function for each configuration items.

  Configuration items can be defined as either a single atom or {name, default} tuple. Each of the items can be included in your `config/config.exs` file.

  The following items are supported:

  * :module`: the name of project module (`module: MyProject`)
  * :repo`: the module name of your Repo (`repo: MyProject.Repo`)
  * :user_schema
  * :schema_key
  * :logged_out_url
  * :email_from
  * :email_reply_to
  * :auth_module (Coherence.Authentication.Database)
  * :create_login (:create_login)
  * :delete_login (:delete_login})
  * :opts ([])
  * :reset_token_expire_days (2)
  * :confirmation_token_expire_days (5)
  * :max_failed_login_attempts (5)
  * :unlock_timeout_minutes (20)
  * :unlock_token_expire_minutes (5)

  ## Examples

      alias Coherence.Config

      Config.module

  """

  # opts: :all || [:trackable, :lockable, :rememberable, :confirmable]
  [
    :module,
    :repo,
    :user_schema,
    :schema_key,
    :logged_out_url,
    :email_from,
    :email_reply_to,
    {:auth_module, Coherence.Authentication.Database},
    {:create_login, :create_login},
    {:delete_login, :delete_login},
    {:opts, []},
    {:reset_token_expire_days, 2},
    {:confirmation_token_expire_days, 5},
    {:max_failed_login_attempts, 5},
    {:unlock_timeout_minutes, 20},
    {:unlock_token_expire_minutes, 5}
  ]
  |> Enum.each(fn
        {key, default} ->
          def unquote(key)(opts \\ unquote(default)) do
            Application.get_env :coherence, unquote(key), opts
          end
        key ->
          def unquote(key)(opts \\ nil) do
            Application.get_env :coherence, unquote(key), opts
          end
     end)

  @doc """
  Get a configuration item.
  """
  def get(key, default \\ nil) do
    Application.get_env :coherence, key, default
  end

  @doc """
  Test if an options is configured.
  """
  def has_option(option) do
    if opts == :all or option in opts, do: true, else: false
  end
end
