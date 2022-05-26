import Config

config :junit_formatter,
  report_file: "elixir-test-results-#{System.get_env("GITHUB_RUN_ID", "without-ci")}.xml",
  report_dir: "reports/junit",
  print_report_file: true,
  include_filename?: true
