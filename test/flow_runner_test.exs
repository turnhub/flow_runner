defmodule FlowRunnerTest do
  use ExUnit.Case
  doctest FlowRunner

  test "compile a flow" do
    {:ok, _flow} =
      File.read!("test/basic.flow")
      |> FlowRunner.compile()
  end

  test "run a flow" do
    {:ok, container} =
      File.read!("test/basic.flow")
      |> FlowRunner.compile()

    flow = Enum.at(container.flows, 0)
    context = %FlowRunner.Context{}
    {:ok, _context, output} = FlowRunner.next_block(container, flow, context)
    assert %{prompt: %{value: "welcome to this block"}} = output
  end

  test "language selection" do
    {:ok, container} =
      File.read!("test/selectoneresponse.flow")
      |> FlowRunner.compile()

    flow = Enum.at(container.flows, 0)

    {:ok, _context, output} =
      FlowRunner.next_block(
        container,
        flow,
        %FlowRunner.Context{
          language: "fra",
          mode: "TEXT"
        }
      )

    assert %{prompt: %{value: "اختر اسمًا"}} = output

    {:ok, _context, output} =
      FlowRunner.next_block(
        container,
        flow,
        %FlowRunner.Context{
          language: "eng",
          mode: "TEXT"
        }
      )

    assert %{prompt: %{value: "choose a name"}} = output
  end

  test "select one response" do
    {:ok, container} =
      File.read!("test/selectoneresponse.flow")
      |> FlowRunner.compile()

    flow = Enum.at(container.flows, 0)

    context = %FlowRunner.Context{
      language: "fra",
      mode: "TEXT"
    }

    {:ok, context, output} = FlowRunner.next_block(container, flow, context)
    assert %{prompt: %{value: "اختر اسمًا"}} = output
    assert %{waiting_for_user_input: true} = context
    {:ok, context, output} = FlowRunner.next_block(container, flow, context, "maalika")
    assert %{prompt: %{value: "salaam maalika"}} = output
    assert %{waiting_for_user_input: false} = context
    {:end, _context} = FlowRunner.next_block(container, flow, context)
  end
end
