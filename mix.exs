defmodule Coherence.Mixfile do
  use Mix.Project

  @version "0.4.0-dev"

  def project do
    [ app: :coherence,
      version: @version,
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      docs: [extras: ["README.md"], main: "Coherence"],
      deps: deps(),
      package: package(),
      dialyzer: [plt_add_apps: [:mix]],
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
                    :timex_ecto, :tzdata, :plug, :phoenix, :phoenix_html]]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  defp deps do
    [
      {:ecto, "~> 2.0"},
      {:comeonin, "~> 3.0"},
      {:phoenix, "~> 1.3.0-rc"},
      {:phoenix_html, "~> 2.6"},
      {:gettext, "~> 0.11"},
      {:uuid, "~> 1.0"},
      {:phoenix_swoosh, git: "https://github.com/vircung/phoenix_swoosh.git", branch: "phx-1.3"},
      {:timex, "~> 3.0"},
      {:timex_ecto, "~> 3.0"},
      {:floki, "~> 0.8", only: :test},
      {:ex_doc, "== 0.11.5", only: :dev},
      {:earmark, "== 0.2.1", only: :dev, override: true},
      {:postgrex, ">= 0.0.0", only: :test},
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
      {:credo, "~> 0.5", only: [:dev, :test]}
    ]
  end

  defp package do
    [ maintainers: ["Stephen Pallen"],
      licenses: ["MIT"],
      links: %{ "Github" => "https://github.com/smpallen99/coherence" },
      files: ~w(lib priv web README.md mix.exs LICENSE)]
  end
end
