defmodule TestCoherence.Repo do
  use Ecto.Repo, otp_app: :coherence, adapter: Ecto.Adapters.Postgres
end
