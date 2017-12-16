defmodule Coherence.Mixfile do
  use Mix.Project

  @version "0.5.1"

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
      {:phoenix, "~> 1.3"},
      {:phoenix_html, "~> 2.10"},
      {:gettext, "~> 0.14"},
      {:uuid, "~> 1.0"},
      {:phoenix_swoosh, "~> 0.2"},
      {:timex, "~> 3.1"},
      {:timex_ecto, "~> 3.2"},
      {:floki, "~> 0.19", only: :test},
      {:ex_doc, "~> 0.18", only: :dev},
      {:earmark, "~> 1.2", only: :dev, override: true},
      {:postgrex, ">= 0.0.0", only: :test},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:credo, "~> 0.8", only: [:dev, :test]},
    ]
  end

  defp package do
    [ maintainers: ["Stephen Pallen"],
      licenses: ["MIT"],
      links: %{ "Github" => "https://github.com/smpallen99/coherence" },
      files: ~w(lib priv README.md mix.exs LICENSE)]
  end
end
