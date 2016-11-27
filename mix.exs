defmodule Coherence.Mixfile do
  use Mix.Project

  @version "0.3.1"

  def project do
    [ app: :coherence,
      version: @version,
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      docs: [extras: ["README.md"], main: "Coherence"],
      deps: deps,
      package: package,
      name: "Coherence",
      description: """
      A full featured, configurable authentication and user management system for Phoenix.
      """
    ]
  end

  # Configuration for the OTP application
  def application do
    [mod: {Coherence, []},
     applications: [:logger, :comeonin, :ecto, :uuid, :phoenix_swoosh,
                    :phoenix_timex, :timex_ecto, :tzdata]]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  defp deps do
    [
      {:ecto, "~> 2.0"},
      {:comeonin, "~> 2.4"},
      {:phoenix, "~> 1.2"},
      {:phoenix_html, "~> 2.6"},
      {:gettext, "~> 0.11"},
      {:uuid, "~> 1.0"},
      {:phoenix_swoosh, "~> 0.1.3"},
      {:phoenix_timex, "~> 1.0.0"},
      {:timex_ecto, "~> 1.1"},
      {:floki, "~> 0.8", only: :test},
      {:ex_doc, "== 0.11.5", only: :dev},
      {:earmark, "== 0.2.1", only: :dev, override: true},
      {:postgrex, ">= 0.0.0", only: :test},
    ]
  end

  defp package do
    [ maintainers: ["Stephen Pallen"],
      licenses: ["MIT"],
      links: %{ "Github" => "https://github.com/smpallen99/coherence" },
      files: ~w(lib priv web README.md mix.exs LICENSE)]
  end
end
