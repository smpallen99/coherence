defmodule Coherence.CredentialStore do
  @moduledoc false

  @callback get_user_data(String.t() | {any, String.t(), any}) :: any
end
