defmodule Coherence.Config do
  @moduledoc """
  Coherence Configuration Module.

  Provides a small wrapper around `Application.get_env :coherence`, providing an accessor function for each configuration items.

  Configuration items can be defined as either a single atom or {name, default} tuple. Each of the items can be included in your `config/config.exs` file.

  The following items are supported:

  * :module: the name of project module (`module: MyProject`)
  * :repo: the module name of your Repo (`repo: MyProject.Repo`)
  * :user_schema
  * :schema_key
  * :logged_out_url
  * :email_from
  * :email_reply_to
  * :site_name                                        - The site name used for email
  * :login_cookie ("coherence_login")                 - The name of the login cookie
  * :auth_module (Coherence.Authentication.Session)
  * :create_login (:create_login)
  * :delete_login (:delete_login})
  * :opts ([])
  * :reset_token_expire_days (2)
  * :confirmation_token_expire_days (5)
  * :max_failed_login_attempts (5)
  * :unlock_timeout_minutes (20)
  * :unlock_token_expire_minutes (5)
  * :session_key ("session_auth")
  * :rememberable_cookie_expire_hours (2*24)
  * :password_hash_field (:password_hash)         - The field used to save the hashed password
  * :login_field (:email)                         - The user model field used to login
  * :changeset                                    - Custom user changeset

  ## Examples

      alias Coherence.Config

      Config.module

  """

  defmacro __using__(_) do
    quote do
      alias unquote(__MODULE__)
    end
  end

  # opts: :all || [:trackable, :lockable, :rememberable, :confirmable]
  [
    :module,
    :repo,
    :user_schema,
    :schema_key,
    :logged_out_url,
    :email_from,
    :email_reply_to,
    :site_name,
    :changeset,
    {:password_hash_field, :password_hash},
    {:login_field, :email},
    {:login_cookie, "coherence_login"},
    {:auth_module, Coherence.Authentication.Session},
    {:create_login, :create_login},
    {:delete_login, :delete_login},
    {:opts, []},
    {:assigns_key, :current_user},
    {:reset_token_expire_days, 2},
    {:confirmation_token_expire_days, 5},
    {:max_failed_login_attempts, 5},
    {:unlock_timeout_minutes, 20},
    {:unlock_token_expire_minutes, 5},
    {:session_key, "session_auth"},
    {:rememberable_cookie_expire_hours, 2*24 }
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
    has_any_option?(fn({name, _actions}) -> name == option end)
  end

  @doc """
  Test if an option is configured and accepts a specific action
  """
  def has_action?(option, action) do
    has_any_option?(fn({name, actions}) ->
      name == option and (actions == :all or action in actions)
    end)
  end

  defp has_any_option?(fun) do
    if opts == :all do
      true
    else
      Enum.any?(opts, &(fun.(standardize_option(&1))))
    end
  end

  defp standardize_option(option) when is_atom(option), do: {option, :all}
  defp standardize_option(option), do: option

  defmacro password_hash do
    field = Application.get_env :coherence, :password_hash_field, :password_hash
    quote do: unquote(field)
  end

end
