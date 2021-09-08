# FlowRunner

Flow Runner implements the Flow Content Interop spec v1.0.0-rc2 as documented at 
https://floip.gitbook.io/flow-specification/. It provides the means to Run a flow defined in the specification and interact with some user.

This Flow Runnner only supports the TEXT, USSD, RICH_MESSAGING modes.

### Modules

- *FlowRunner.Compiler* parses and compiles JSON flows according to the content spec into an internal representation that can be Run.

- *FlowRunner.Run* takes a compiled flow, a state and a context and returns new state and user IO.

- *FlowRunner.Context* is a struct that contains context for a run. It contains the channel, contact and .

## Design

The Flow Runner is a pure module that stores no state. The Flow Runner manages the transitions between states within the flow and then yields to the caller to provide input for the next block. 

The Flow Runner does not perform the following and is the responsibility of the caller:
- Perform IO or send and receive any messages.
- Associate a given message to any flow.
- Manage contacts.
- Store state of a Flow Run or Flow Results.

Running a flow works in the following way:


1. The caller receives a message, identifies the corresponding Flow, contact and looks up the contacts Flow state (last block id).
1. The JSON flow is compiled by the FlowRunner.Compiler. This result may be cached.
1. FlowRunner.Run is passed the flow, Context and last Block ID.
1. The Flow Runner returns the result, last block ID and the potentially updated context.

TODO figure out interaction with contacts.

TODO figure out interaction with channels.

TODO how can we support webhooks without doing IO in the runner?

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `flow_runner` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:flow_runner, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/flow_runner](https://hexdocs.pm/flow_runner).

