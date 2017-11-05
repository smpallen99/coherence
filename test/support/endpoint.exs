defmodule TestCoherenceWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :coherence

  # def config(one, two) do
  #   IO.puts "endpoint config one: #{inspect one}, two: #{inspect two}"
  #   String.duplicate("abcdefgh", 8)
  # end
  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :coherence, gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_binaryid_key",
    signing_salt: "JFbk5iZ6"

  plug TestCoherenceWeb.Router
end
