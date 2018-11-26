defmodule Coherence.CredentialStore.Types do
  @type credentials :: String.t
  @type user_data :: Ecto.Schema.t | Map.t
  @type user_id :: any
end