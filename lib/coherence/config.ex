defmodule Coherence.Config do

  # opts: :all || [:resettable, :trackable, :lockable, :rememberable, :confirmable]
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
    {:unlock_timeout_minutes, 20}
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

  def get(key, default \\ nil) do
    Application.get_env :coherence, key, default
  end

  def has_option(option) do
    if opts == :all or option in opts, do: true, else: false
  end
end
