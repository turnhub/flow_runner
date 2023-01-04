defmodule FlowRunner.MixProject do
  use Mix.Project

  @version "3.5.0"

  def project do
    [
      app: :flow_runner,
      aliases: aliases(),
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix],
        ignore_warnings: "config/dialyzer.ignore"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def description() do
    "A FLOIP spec compatible flow runner"
  end

  def package() do
    [
      name: "flow_runner",
      organization: "turnio",
      licenses: ["AGPL-3.0"],
      links: %{
        "Github" => "https://github.com/turnhub/flowrunner"
      }
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:credo, "~> 1.5", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:elixir_uuid, "~> 1.2"},
      {:excoveralls, "~> 0.10", only: :test},
      {:expression, "~> 2.10"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:jason, "~> 1.2"},
      {:junit_formatter, "~> 3.1", only: [:test]},
      {:mix_test_watch, "~> 1.1", only: [:dev, :test], runtime: false},
      {:version_tasks, "~> 0.12.0", only: [:dev], runtime: false},
      {:vex, "~> 0.9.0"}
    ]
  end

  defp aliases do
    [
      "release.major": ["version.up major", "version.tag"],
      "release.minor": ["version.up minor", "version.tag"],
      "release.patch": ["version.up patch", "version.tag"]
    ]
  end
end
