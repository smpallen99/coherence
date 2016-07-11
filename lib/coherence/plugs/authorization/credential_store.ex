defmodule Coherence.CredentialStore do
  @moduledoc false
  use Behaviour

  @callback get_user_data(HashDict.t) :: any
end
