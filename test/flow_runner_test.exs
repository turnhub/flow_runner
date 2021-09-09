defmodule FlowRunnerTest do
  use ExUnit.Case
  doctest FlowRunner

  test "compile a flow" do
    {:ok, _flow} = File.read!("test/basic.flow") 
      |> FlowRunner.compile
  end

  #test "run a flow" do
  #  {:ok, flow} = File.read!("test/basic.flow") 
  #    |> FlowRunner.compile()

  #  context = %FlowRunner.Context{}
  #  {:ok, _result, context} = FlowRunner.run(flow, context)
  #  {:ok, _result, context} = FlowRunner.run(flow, context)
  #  {:finished} = FlowRunner.run(flow, context)
  #end
end
