defmodule Coherence.Config do

  [
    :module,
    :repo,
    :user_schema,
    :schema_key,
    :logged_out_url,
    {:auth_module, Coherence.Authentication.Database},
    {:create_login, :create_login},
    {:delete_login, :delete_login},
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
end
