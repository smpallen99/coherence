defmodule Coherence.Config do
  @moduledoc """
  Coherence Configuration Module.

  Provides a small wrapper around `Application.get_env :coherence`, providing an accessor function for each configuration items.

  Configuration items can be defined as either a single atom or {name, default} tuple. Each of the items can be included in your `config/config.exs` file.

  The following items are supported:

  * :module - the name of project module (`module: MyProject`)
  * :web_module - the name of the project's web module (`web_module: MyProjectWeb`)
  * :repo: the module name of your Repo (`repo: MyProject.Repo`)
  * :user_schema
  * :schema_key
  * :logged_out_url
  * :logged_in_url
  * :email_from                                       - Deprecated. Use `email_from_name` and `email_from_email` instead
  * :email_from_name
  * :email_from_email
  * :email_reply_to                                   - Set to true to add email_from_name and email_from_email
  * :email_reply_to_name
  * :email_reply_to_email
  * :site_name                                        - The site name used for email
  * :login_cookie ("coherence_login")                 - The name of the login cookie
  * :auth_module (Coherence.Authentication.Session)
  * :create_login (:create_login)
  * :update_login (:update_login)
  * :delete_login (:delete_login)
  * :opts ([])
  * :reset_token_expire_days (2)
  * :confirmation_token_expire_days (5)
  * :allow_unconfirmed_access_for (0)             - default 0 days
  * :max_failed_login_attempts (5)
  * :unlock_timeout_minutes (20)
  * :unlock_token_expire_minutes (5)
  * :session_key ("session_auth")
  * :rememberable_cookie_expire_hours (2*24)
  * :password_hash_field (:password_hash) - The field used to save the hashed password
  * :login_field (:email) - The user model field used to login
  * :changeset - Custom user changeset
  * :title  - Layout page title
  * :layout - Customize the layout template e.g. {MyApp.LayoutView, "app.html"}
  * :async_rememberable? (false) - Don't update rememberable seq_no for ajax requests
  * :user_token (false) - generate tokens for channel authentication
  * :token_assigns_key (:user_token) - key used to access the channel_token in the conn.assigns map
  * :token_generator   (fn conn, user -> Phoenix.Token.sign(conn, "user socket", user.id) end) - override the default
  *                    may also provide an arity 3 function as a tuple {Module, :function, args}
  *                    where apply(Module, function, args) will be used
  * :verify_user_token (fn socket, token -> Phoenix.Token.verify(socket, "user socket", token, max_age: 2 * 7 * 24 * 60 * 60) end
  *                    can also be a 3 element tuple as described above for :token_generator
  * :use_binary_id (false) - Use binary ids.
  * :minimum_password_length The minimum password length to be accepted. Default value is 4.
  * :messages_backend - (MyApp.Coherence.Messages)
  * :router: the module name of your Router (`router: MyProject.Router`)
  * :user_active_field - Include the user active feature

  ## Examples

      alias Coherence.Config

      Config.module

  """

  defmacro __using__(_) do
    quote do
      alias unquote(__MODULE__)
    end
  end

  require Logger

  # opts: :all || [:trackable, :lockable, :rememberable, :confirmable]
  [
    :module,
    :web_module,
    :repo,
    :user_schema,
    :schema_key,
    :logged_out_url,
    :logged_in_url,
    :email_from_name,
    :email_from_email,
    :email_reply_to_name,
    :email_reply_to_email,
    :site_name,
    :changeset,
    :layout,
    :user_token,
    :use_binary_id,
    {:token_assigns_key, :user_token},
    {:token_generator, &Coherence.SessionService.sign_user_token/2},
    {:verify_user_token, &Coherence.SessionService.verify_user_token/2},
    {:password_hash_field, :password_hash},
    {:login_field, :email},
    {:login_cookie, "coherence_login"},
    {:auth_module, Coherence.Authentication.Session},
    {:create_login, :create_login},
    {:update_login, :update_login},
    {:delete_login, :delete_login},
    {:opts, []},
    {:assigns_key, :current_user},
    {:require_current_password, true},
    {:reset_token_expire_days, 2},
    {:confirmation_token_expire_days, 5},
    {:allow_unconfirmed_access_for, 0},
    {:max_failed_login_attempts, 5},
    {:unlock_timeout_minutes, 20},
    {:unlock_token_expire_minutes, 5},
    {:session_key, "session_auth"},
    {:rememberable_cookie_expire_hours, 2 * 24},
    {:async_rememberable?, false},
    {:minimum_password_length, 4},
    :messages_backend,
    :router,
    :user_active_field
  ]
  |> Enum.each(fn
        {key, default} ->
          def unquote(key)(opts \\ unquote(default)) do
            get_application_env unquote(key), opts
          end
        key ->
          def unquote(key)(opts \\ nil) do
            get_application_env unquote(key), opts
          end
     end)

  @spec email_from() :: {nil, nil} | {String.t, String.t} | String.t
  def email_from do
    case get_application_env :email_from do
      nil ->
        {get_application_env(:email_from_name), get_application_env(:email_from_email)}
      email ->
        Logger.info "email_from config is deprecated. Use email_from_name and email_from_email instead"
        email
    end
  end

  @spec email_reply_to() :: {nil, nil} | true | {String.t, String.t} | String.t
  def email_reply_to do
    case get_application_env :email_reply_to do
      nil ->
        case {get_application_env(:email_reply_to_name), get_application_env(:email_reply_to_email)} do
          {nil, nil} -> nil
          email -> email
        end
      true -> true
      email ->
        Logger.info "email_reply_to {name, email} config is deprecated. Use email_reply_to_name and email_reply_to_email instead"
        email
    end
  end

  @doc """
  Get title
  """
  @spec title() :: String.t | nil
  def title, do: get_application_env(:title, get(:module))

  @doc """
  Get a configuration item.
  """
  @spec get(atom, any) :: any
  def get(key, default \\ nil) do
    get_application_env key, default
  end

  @doc """
  Test if an options is configured.
  """
  @spec has_option(atom) :: boolean
  def has_option(option) do
    has_any_option?(fn({name, _actions}) -> name == option end)
  end

  @doc """
  Test if an option is configured and accepts a specific action
  """
  @spec has_action?(atom, atom) :: boolean
  def has_action?(option, action) do
    has_any_option?(fn({name, actions}) ->
      name == option and (actions == :all or action in actions)
    end)
  end

  @doc """
  Test if Phoenix is configured to use binary ids by default
  """
  @spec use_binary_id?() :: boolean
  def use_binary_id? do
    !!Application.get_env(:phoenix, :generators, [])[:binary_id] || Application.get_env(:coherence, :use_binary_id)
  end

  defp has_any_option?(fun) do
    if opts() == :all do
      true
    else
      Enum.any?(opts(), &(fun.(standardize_option(&1))))
    end
  end

  defp standardize_option(option) when is_atom(option), do: {option, :all}
  defp standardize_option(option), do: option

  defmacro password_hash do
    field = Application.get_env :coherence, :password_hash_field, :password_hash
    quote do: unquote(field)
  end

  defp get_application_env(key, default \\ nil) do
    case Application.get_env :coherence, key, default do
      {:system, env_var} -> System.get_env env_var
      value -> value
    end
  end

  def mailer? do
    !!Application.get_env(:coherence, Module.concat(web_module(), Coherence.Mailer))
  end

end
