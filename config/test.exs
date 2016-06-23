use Mix.Config

# config :coherence, ecto_repos: [TestCoherence.Repo]

config :logger, level: :warn

config :coherence, TestCoherence.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "coherence_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
