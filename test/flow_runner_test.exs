defmodule FlowRunnerTest do
  use ExUnit.Case
  doctest FlowRunner

  test "greets the world" do
    assert FlowRunner.hello() == :world
  end
end
