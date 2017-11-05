use Mix.Config

# config :coherence, ecto_repos: [TestCoherence.Repo]

config :logger, level: :error

config :coherence, TestCoherenceWeb.Endpoint,
  http: [port: 4001],
  secret_key_base: "HL0pikQMxNSA58Dv4mf26O/eh1e4vaJDmX0qLgqBcnS94gbKu9Xn3x114D+mHYcX",
  server: false

config :coherence, TestCoherence.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "coherence_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :coherence,
  user_schema: TestCoherence.User,
  repo: TestCoherence.Repo,
  router: TestCoherenceWeb.Router,
  module: TestCoherence,
  web_module: TestCoherenceWeb,
  layout: {Coherence.LayoutView, :app},
  messages_backend: TestCoherenceWeb.Coherence.Messages,
  logged_out_url: "/",
  email_from_name: "Your Name",
  email_from_email: "yourname@example.com",
  opts: [:confirmable, :authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token, :invitable, :registerable, :rememberable]

