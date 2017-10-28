# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :coherence, Coherence.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: ""

config :coherence,
  password_hashing_alg: Comeonin.Bcrypt

import_config "#{Mix.env}.exs"

