use Mix.Config

# config :coherence, ecto_repos: [TestCoherence.Repo]

config :logger, level: :error

config :coherence, TestCoherenceWeb.Endpoint,
  http: [port: 4001],
  secret_key_base: "HL0pikQMxNSA58Dv4mf26O/eh1e4vaJDmX0qLgqBcnS94gbKu9Xn3x114D+mHYcX",
  server: false

config :coherence, ecto_repos: [TestCoherence.Repo]

config :coherence, TestCoherence.Repo,
  username: System.get_env("DB_USERNAME") || "postgres",
  password: System.get_env("DB_PASSWORD") || "postgres",
  database: "coherence_test",
  hostname: System.get_env("DB_HOSTNAME") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :coherence,
  user_schema: TestCoherence.User,
  password_hashing_alg: Comeonin.Bcrypt,
  repo: TestCoherence.Repo,
  router: TestCoherenceWeb.Router,
  module: TestCoherence,
  web_module: TestCoherenceWeb,
  layout: {Coherence.LayoutView, :app},
  messages_backend: TestCoherenceWeb.Coherence.Messages,
  logged_out_url: "/",
  email_from_name: "Your Name",
  email_from_email: "yourname@example.com",
  opts: [
    :confirmable,
    :authenticatable,
    :recoverable,
    :lockable,
    :trackable,
    :unlockable_with_token,
    :invitable,
    :registerable,
    :rememberable
  ],
  registration_permitted_attributes: [
    "email",
    "name",
    "password",
    "password_confirmation",
    "current_password"
  ],
  invitation_permitted_attributes: ["name", "email"],
  password_reset_permitted_attributes: [
    "reset_password_token",
    "password",
    "password_confirmation"
  ],
  session_permitted_attributes: ["remember", "email", "password"],
  confirm_email_updates: true

config :bcrypt_elixir, log_rounds: 4
