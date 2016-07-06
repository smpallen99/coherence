defmodule Coherence.CredentialStore do
  use Behaviour

  @callback get_user_data(HashDict.t) :: any
end
