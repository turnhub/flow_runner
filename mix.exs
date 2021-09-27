defmodule FlowRunner.MixProject do
  use Mix.Project

  def project do
    [
      app: :flow_runner,
      version: String.trim(File.read!("VERSION")),
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
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
      {:excoveralls, "~> 0.10", only: :test},
      {:expression, "~> 0.3.1"},
      {:junit_formatter, "~> 3.1", only: [:test]},
      {:mix_test_watch, "~> 1.1", only: [:dev, :test], runtime: false},
      {:poison, "~> 5.0", override: true}
    ]
  end
end
