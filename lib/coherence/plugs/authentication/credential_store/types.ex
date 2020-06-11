defmodule Coherence.CredentialStore.Types do
  @type credentials :: String.t()
  @type user_data :: Ecto.Schema.t() | map()
  @type user_id :: any
end
