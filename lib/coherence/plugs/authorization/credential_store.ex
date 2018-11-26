defmodule Coherence.CredentialStore do
  @moduledoc false

  @callback get_user_data(String.t | {String.t, any, any}) :: any
end
