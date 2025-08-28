defmodule FlowRunner.MixProject do
  use Mix.Project

  @version "6.2.0"

  def project do
    [
      app: :flow_runner,
      aliases: aliases(),
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:yecc] ++ Mix.compilers(),
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix],
        ignore_warnings: "config/dialyzer.ignore.exs"
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
      {:bypass, "~> 2.1"},
      {:credo, "~> 1.5", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:elixir_uuid, "~> 1.2"},
      {:excoveralls, "~> 0.10", only: :test},
      {:expression, "~> 2.46.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:finch, "~> 0.17"},
      {:iptools, "~> 0.0.5"},
      {:jason, "~> 1.2"},
      {:junit_formatter, "~> 3.1", only: [:test]},
      {:mix_test_watch, "~> 1.1", only: [:dev, :test], runtime: false},
      {:open_telemetry_decorator, "<=1.4.13 or >1.5.6"},
      {:tesla, "~> 1.11"},
      {:version_tasks, "~> 0.12.0",
       only: [:dev], runtime: false, github: "turnhub/version_tasks"},
      {:vex, "~> 0.9.0"}
    ]
  end

  defp aliases do
    [
      "release.major": ["version.up major", "version.tag"],
      "release.minor": ["version.up minor", "version.tag"],
      "release.patch": ["version.up patch", "version.tag"],
      "release.rc": ["version.up rc", "version.tag"]
    ]
  end
end
