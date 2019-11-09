defmodule Coherence.Mixfile do
  use Mix.Project

  @version "0.6.1"

  def project do
    [
      app: :coherence,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
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
    [
      mod: {Coherence, []},
      applications: [
        :logger,
        :comeonin,
        :ecto_sql,
        :elixir_uuid,
        :phoenix_swoosh,
        :tzdata,
        :plug,
        :phoenix,
        :phoenix_html
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_), do: ["lib", "web"]

  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:comeonin, "~> 4.0"},
      {:bcrypt_elixir, "~> 1.1"},
      {:phoenix, "~> 1.4"},
      {:phoenix_html, "~> 2.12"},
      {:gettext, "~> 0.14"},
      {:elixir_uuid, "~> 1.2"},
      {:phoenix_swoosh, "~> 0.2"},
      {:timex, "~> 3.3"},
      {:floki, "~> 0.19", only: :test},
      {:ex_doc, "~> 0.18.0", only: :dev},
      {:earmark, "~> 1.2", only: :dev, override: true},
      {:postgrex, "~> 0.14.0", only: :test},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:credo, "~> 0.8", only: [:dev, :test]},
      {:plug, "~> 1.7.1"},
      {:jason, "~> 1.0"}
    ]
  end

  defp package do
    [
      maintainers: ["Stephen Pallen"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/smpallen99/coherence"},
      files: ~w(lib priv README.md mix.exs LICENSE)
    ]
  end
end
