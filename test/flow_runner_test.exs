defmodule FlowRunnerTest do
  use ExUnit.Case
  doctest FlowRunner

  test "compile a flow" do
    {:ok, _flow} = File.read!("test/basic.flow") 
      |> FlowRunner.compile
  end

  test "run a flow" do
    {:ok, _result, _context, _uuid} = File.read!("test/basic.flow") 
      |> FlowRunner.compile()
      |> FlowRunner.run(%FlowRunner.Context{})
  end
end
