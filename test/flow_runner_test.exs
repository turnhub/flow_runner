defmodule FlowRunnerTest do
  use ExUnit.Case
  doctest FlowRunner

  test "compile a flow" do
    {:ok, _flow} = File.read!("test/basic.flow") 
      |> FlowRunner.compile
  end

  test "run a flow" do
    {:ok, container} = File.read!("test/basic.flow") 
      |> FlowRunner.compile()

    flow = Enum.at(container.flows, 0)
    context = %FlowRunner.Context{}
    {:ok, _context, _resource} = FlowRunner.next_block(flow, context)
  end
end
