defmodule MegaTest do
  use ExUnit.Case
  import FlowRunner.Test.Utils

  setup :with_flow_loader!

  @tag flow: "test/mega_test.flow"
  test "Test all blocks in one flow", %{container: container} do
    {:error, "no matching flow"} =
      FlowRunner.create_context(container, "62d0084d-e88f-48c3-ac64-7a15855f0a43", "eng", "TEXT")

    {:ok, context} =
      FlowRunner.create_context(container, "ee84b2b7-ca0f-4492-a964-fdc5eb83dd47", "eng", "TEXT")

    {:ok, context, _, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "welcome to the MEGA test"}} = output

    # Test Core.Log
    {:ok, context, _, _output} = FlowRunner.next_block(container, context)
    assert %{log: ["we are logging the mega test"]} = context

    # Test MobilePrimitive.SelectOneResponse
    {:ok, context, _, output} = FlowRunner.next_block(container, context)

    assert %{
             prompt: %{
               value: "do you want to CONTINUE or START AGAIN"
             },
             choices: [{"continue", "continue"}, {"start_again", "start again"}]
           } = output

    # Choose start_again
    {:ok, _context, _, output} = FlowRunner.next_block(container, context, "start_again")
    assert %{prompt: %{value: "welcome to the MEGA test"}} = output

    # Choose something none of the choices and proceed through default exit.
    {:ok, _context, _, output} = FlowRunner.next_block(container, context, "something else")
    assert %{prompt: %{value: "you chose none of them"}} = output

    # Choose continue
    {:ok, context, _, output} = FlowRunner.next_block(container, context, "continue")
    assert %{prompt: %{value: "what is your name?"}} = output

    # See that max_response_characters works.
    {:ok, _context, _, output} =
      FlowRunner.next_block(container, context, "longer name than we allow")

    assert %{prompt: %{value: "your name or age is either too long or not a number or something"}} =
             output

    # And then a valid response. Test MobilePrimitive.NumericResponse
    {:ok, context, _, output} = FlowRunner.next_block(container, context, "yaseen")
    assert %{prompt: %{value: "yaseen what is your age?"}} = output

    # What happens if we give NumericResponse a non-numeric input?
    {:ok, _context, _, output} = FlowRunner.next_block(container, context, "not a number")

    assert %{prompt: %{value: "your name or age is either too long or not a number or something"}} =
             output

    # Ok let's give it real input again
    {:ok, context, _, output} = FlowRunner.next_block(container, context, "11")

    assert %{prompt: %{value: "i think we're done here"}} = output

    {:end, %{log: ["we are logging the mega test"]}} = FlowRunner.next_block(container, context)
  end
end
