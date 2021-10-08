# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :vex,
  sources: [[subset: FlowRunner.Spec.Validators.SubsetValidator], Vex.Validators]

import_config "#{Mix.env()}.exs"
