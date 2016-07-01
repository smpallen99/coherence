defmodule Coherence.Mixfile do
  use Mix.Project

  def project do
    [app: :coherence,
     version: "0.0.1",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [mod: {Coherence, []},
     applications: [:logger, :comeonin, :ecto, :postgrex, :uuid, :phoenix_swoosh,
                    :phoenix_timex, :tzdata]]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  defp deps do
    [
      {:ecto, "~> 2.0"},
      {:comeonin, "~> 2.4"},
      {:phoenix, "~> 1.1"},
      {:phoenix_html, "~> 2.4"},
      {:gettext, "~> 0.9"},
      {:uuid, "~> 1.0"},
      {:phoenix_swoosh, "~> 0.1.3"},
      {:phoenix_timex, "~> 1.0.0"},
      {:postgrex, ">= 0.0.0", only: :test},
    ]
  end
end
