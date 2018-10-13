defmodule Coherence.Config do
  @moduledoc """
  Coherence Configuration Module.

  Provides a small wrapper around `Application.get_env :coherence`, providing an
  accessor function for each configuration items.

  Configuration items can be defined as either a single atom or {name, default}
  tuple. Each of the items can be included in your `config/config.exs` file.

  The following items are supported:

  * :allow_silent_password_recovery_for_unknown_user (false)
  * :allow_unconfirmed_access_for (0) - default 0 days
  * :assigns_key (:current_user)
  * :async_rememberable? (false) - Don't update rememberable seq_no for ajax requests
  * :auth_module (Coherence.Authentication.Session)
  * :changeset - Custom user changeset
  * :confirm_email_updates (false)  - All email updates should be confirmed by email (using the unconfirmed_email field)
  * :confirmation_token_expire_days (5)
  * :create_login (:create_login)
  * :credential_store - override the credential store module
  * :delete_login (:delete_login)
  * :email_from  - Deprecated. Use `email_from_name` and `email_from_email` instead
  * :email_from_email
  * :email_from_name
  * :email_reply_to - Set to true to add email_from_name and email_from_email
  * :email_reply_to_email
  * :email_reply_to_name
  * :invitation_permitted_attributes - List of allowed invitation parameter attribues as strings
  * :layout - Customize the layout template e.g. {MyApp.LayoutView, "app.html"}
  * :log_emails - Set to true to log each rendered email.
  * :logged_in_url
  * :logged_out_url
  * :login_cookie ("coherence_login")                 - The name of the login cookie
  * :login_field (:email) - The user model field used to login
  * :max_failed_login_attempts (5)
  * :messages_backend - (MyApp.Coherence.Messages)
  * :minimum_password_length The minimum password length to be accepted. Default value is 4.
  * :module - the name of project module (`module: MyProject`)
  * :opts ([])
  * :password_hash_field (:password_hash) - The field used to save the hashed password
  * :password_hashing_alg (Comeonin.Bcrypt) - Password hashing algorithm to use.
  * :password_reset_permitted_attributes - List of allowed password reset atributes as stings,
  * :registration_permitted_attributes - List of allowed registration parameter attributes as strings
  * :repo: the module name of your Repo (`repo: MyProject.Repo`)
  * :rememberable_cookie_expire_hours (2*24)
  * :reset_token_expire_days (2)
  * :router: the module name of your Router (`router: MyProject.Router`)
  * :schema_key
  * :session_key ("session_auth")
  * :session_permitted_attributes - List of allowed session attributes as strings
  * :site_name                                        - The site name used for email
  * :title  - Layout page title
  * :token_assigns_key (:user_token) - key used to access the channel_token in the conn.assigns map
  * :token_generator   (fn conn, user -> Phoenix.Token.sign(conn, "user socket", user.id) end) - override the default
    may also provide an arity 3 function as a tuple {Module, :function, args}
    where apply(Module, function, args) will be used
  * :token_max_age (2 * 7 * 24 * 60 * 60) - Phoenix.Token max_age
  * :token_salt ("user socket") - Phoenix.Token salt
  * :update_login (:update_login)
  * :unlock_timeout_minutes (20)
  * :unlock_token_expire_minutes (5)
  * :use_binary_id (false) - Use binary ids.
  * :user_active_field - Include the user active feature
  * :user_token (false) - generate tokens for channel authentication
  * :user_schema
  * :verify_user_token (fn socket, token -> Phoenix.Token.verify(socket, "user socket", token, max_age: 2 * 7 * 24 * 60 * 60) end
    can also be a 3 element tuple as described above for :token_generator
  * :web_module - the name of the project's web module (`web_module: MyProjectWeb`)

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

  [
    {:allow_silent_password_recovery_for_unknown_user, false},
    {:allow_unconfirmed_access_for, 0},
    {:assigns_key, :current_user},
    {:async_rememberable?, false},
    {:auth_module, Coherence.Authentication.Session},
    :changeset,
    {:confirm_email_updates, false},
    {:confirmation_token_expire_days, 5},
    {:create_login, :create_login},
    :credential_store,
    {:delete_login, :delete_login},
    :email_from_email,
    :email_from_name,
    :email_reply_to_email,
    :email_reply_to_name,
    {:forwarded_invitation_fields, [:email, :name]},
    :invitation_permitted_attributes,
    :layout,
    :log_emails,
    :logged_in_url,
    :logged_out_url,
    {:login_cookie, "coherence_login"},
    {:login_field, :email},
    {:max_failed_login_attempts, 5},
    :messages_backend,
    {:minimum_password_length, 4},
    :module,
    {:opts, []},
    {:password_hash_field, :password_hash},
    {:password_hashing_alg, Comeonin.Bcrypt},
    :password_reset_permitted_attributes,
    :registration_permitted_attributes,
    {:rememberable_cookie_expire_hours, 48},
    :repo,
    {:require_current_password, true},
    {:reset_token_expire_days, 2},
    :router,
    :schema_key,
    {:session_key, "session_auth"},
    :session_permitted_attributes,
    :site_name,
    {:token_assigns_key, :user_token},
    {:token_generator, &Coherence.SessionService.sign_user_token/2},
    {:token_max_age, 1_209_600},
    {:token_salt, "user socket"},
    {:unlock_timeout_minutes, 20},
    {:unlock_token_expire_minutes, 5},
    {:update_login, :update_login},
    :use_binary_id,
    :user_active_field,
    :user_schema,
    :user_token,
    {:verify_user_token, &Coherence.SessionService.verify_user_token/2},
    :web_module
  ]
  |> Enum.each(fn
    {key, default} ->
      def unquote(key)(opts \\ unquote(default)) do
        get_application_env(unquote(key), opts)
      end

    key ->
      def unquote(key)(opts \\ nil) do
        get_application_env(unquote(key), opts)
      end
  end)

  @doc """
  Get the email_from configuration
  """
  @spec email_from() :: {nil, nil} | {String.t(), String.t()} | String.t()
  def email_from do
    case get_application_env(:email_from) do
      nil ->
        {get_application_env(:email_from_name), get_application_env(:email_from_email)}

      email ->
        Logger.info(
          "email_from config is deprecated. Use email_from_name and email_from_email instead"
        )

        email
    end
  end

  @doc """
  Get the email_reply_to value.

  Fetches `:email_reply_to` from coherence configuration

    * if nil, returns {config[:email_reply_to_name], config[:email_reply_to_email]}
    * if true, returns true
    * if email, returns email with a deprecation logged
  """
  @spec email_reply_to() :: nil | true | {String.t(), String.t()} | String.t()
  def email_reply_to do
    case get_application_env(:email_reply_to) do
      nil ->
        case {get_application_env(:email_reply_to_name),
              get_application_env(:email_reply_to_email)} do
          {nil, nil} -> nil
          email -> email
        end

      true ->
        true

      email ->
        Logger.info(
          "email_reply_to {name, email} config is deprecated. Use email_reply_to_name and email_reply_to_email instead"
        )

        email
    end
  end

  @doc """
  Get title
  """
  @spec title() :: String.t() | nil
  def title, do: get_application_env(:title, get(:module))

  @doc """
  Get a configuration item.
  """
  @spec get(atom, any) :: any
  def get(key, default \\ nil) do
    get_application_env(key, default)
  end

  @doc """
  Test if an options is configured.
  """
  @spec has_option(atom) :: boolean
  def has_option(option) do
    has_any_option?(fn {name, _actions} -> name == option end)
  end

  @doc """
  Test if an option is configured and accepts a specific action
  """
  @spec has_action?(atom, atom) :: boolean
  def has_action?(option, action) do
    has_any_option?(fn {name, actions} ->
      name == option and (actions == :all or action in actions)
    end)
  end

  @doc """
  Test if Phoenix is configured to use binary ids by default
  """
  @spec use_binary_id?() :: boolean
  def use_binary_id? do
    !!Application.get_env(:phoenix, :generators, [])[:binary_id] ||
      Application.get_env(:coherence, :use_binary_id)
  end

  defp has_any_option?(fun) do
    if opts() == :all do
      true
    else
      Enum.any?(opts(), &fun.(standardize_option(&1)))
    end
  end

  defp standardize_option(option) when is_atom(option), do: {option, :all}
  defp standardize_option(option), do: option

  @doc """
  Macro to fetch the password_hash field.

  Use a macro here to optimize performance.
  """
  defmacro password_hash do
    field = Application.get_env(:coherence, :password_hash_field, :password_hash)
    quote do: unquote(field)
  end

  defp get_application_env(key, default \\ nil) do
    case Application.get_env(:coherence, key, default) do
      {:system, env_var} -> System.get_env(env_var)
      value -> value
    end
  end

  @doc """
  Get the configured mailer adapter
  """
  def mailer? do
    !!Application.get_env(:coherence, Module.concat(web_module(), Coherence.Mailer))
  end

  @doc """
  Get the configured routes.

  If config[:default_routes] is nil, return the default routes, otherwise, return
  the the configured map.


  ## Examples

      iex Application.put_env(:coherence, :default_routes, %{
        passwords: "/passwords",
        sessions: "/sessions",
      })
      :ok
      iex Coherence.Config.default_routes()
      %{
        passwords: "/passwords",
        sessions: "/sessions",
      })

  """
  def default_routes do
    case Application.get_env(:coherence, :default_routes) do
      nil ->
        %{
          registrations_new: "/registrations/new",
          registrations: "/registrations",
          passwords: "/passwords",
          confirmations: "/confirmations",
          unlocks: "/unlocks",
          invitations: "/invitations",
          invitations_create: "/invitations/create",
          invitations_resend: "/invitations/:id/resend",
          sessions: "/sessions",
          registrations_edit: "/registrations/edit"
        }

      %{} = config ->
        config

      true ->
        Logger.info("The configuration for default_routes must be a map")
        nil
    end
  end
end
