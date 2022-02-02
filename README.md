# FlowRunner

Flow Runner implements the Flow Content Interop spec v1.0.0-rc2 as documented at
https://floip.gitbook.io/flow-specification/. It provides the means to Run a flow defined in the specification and interact with some user.

This Flow Runnner only supports the TEXT, RICH_MESSAGING modes.

# Implemented from the Spec

| Layer | Block                                 | Implemented? | Notes                           |
| ----- | ------------------------------------- | ------------ | ------------------------------- |
| 1     | Core.Log                              | Yes          |                                 |
| 1     | Core.Case                             | Yes          |                                 |
| 1     | Core.RunFlow                          | Yes          |                                 |
| 1     | Core.SetContactProperty               | Yes          |                                 |
| 1     | Core.SetGroupMembership               | Yes          |                                 |
| 2     | ConsoleIO.Print                       | No           | This is not useful for us.      |
| 2     | ConsoleIO.Read                        | No           | This is not useful for us.      |
| 3     | MessagePrimitives.Message             | Yes          |
| 3     | MessagePrimitives.SelectOneResponse   | Yes          |
| 3     | MessagePrimitives.SelectManyResponses | No           | WhatsApp does not support this. |
| 3     | MessagePrimitives.NumericResponse     | Yes          |
| 3     | MessagePrimitives.OpenResponse        | Yes          |
| 4     | SmartDevices.LocationResponse         | No           | TBD                             |
| 4     | SmartDevices.PhotoResponse            | No           | TBD                             |

# How to use the API

# What is a Context.

# What is an Output.

### Modules

- _FlowRunner.Compiler_ parses and compiles JSON flows according to the content spec into an internal representation that can be Run.

- _FlowRunner.Run_ takes a compiled flow, a state and a context and returns new state and user IO.

- _FlowRunner.Context_ is a struct that contains context for a run. It contains the channel, contact and .

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `flow_runner` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:flow_runner, "~> 0.7.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/flow_runner](https://hexdocs.pm/flow_runner).
