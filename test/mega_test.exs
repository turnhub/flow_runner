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

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)

    assert resource_value(container, flow, context, block.config.prompt) ==
             "welcome to the MEGA test"

    # Test Core.Log
    {:ok, container, _flow, _block, context} = FlowRunner.next_block(container, context)
    assert %{log: ["we are logging the mega test"]} = context

    # Test MobilePrimitive.SelectOneResponse
    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)

    assert %{
             prompt: menu_prompt,
             choices: [
               %{
                 name: "continue",
                 prompt: continue_prompt,
                 test: "block.response = \"continue\""
               },
               %{
                 name: "start_again",
                 prompt: start_again_prompt,
                 test: "block.response = \"start_again\""
               }
             ]
           } = block.config

    assert resource_value(container, flow, context, menu_prompt) ==
             "do you want to CONTINUE or START AGAIN"

    assert resource_value(container, flow, context, continue_prompt) ==
             "continue"

    assert resource_value(container, flow, context, start_again_prompt) ==
             "start again"

    # Choose start_again
    {:ok, container, flow, block, context} =
      FlowRunner.next_block(container, context, "start_again")

    assert resource_value(container, flow, context, block.config.prompt) ==
             "welcome to the MEGA test"

    {:ok, container, _flow, _block, context} = FlowRunner.next_block(container, context)

    # Test Core.Log again
    assert %{log: ["we are logging the mega test", "we are logging the mega test"]} = context

    # Test MobilePrimitive.SelectOneResponse
    {:ok, container, _flow, _block, context} = FlowRunner.next_block(container, context)

    # Choose something none of the choices and proceed through default exit.
    {:ok, container, flow, block, _context} =
      FlowRunner.next_block(container, context, "something else")

    assert resource_value(container, flow, context, block.config.prompt) ==
             "you chose none of them"

    # Choose continue
    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context, "continue")
    assert resource_value(container, flow, context, block.config.prompt) == "what is your name?"
    # See that max_response_characters works.
    {:ok, container, flow, block, _context} =
      FlowRunner.next_block(container, context, "longer name than we allow")

    assert resource_value(container, flow, context, block.config.prompt) ==
             "your name or age is either too long or not a number or something"

    # And then a valid response. Test MobilePrimitive.NumericResponse
    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context, "yaseen")

    assert resource_value(container, flow, context, block.config.prompt) ==
             "@(block.value) what is your age?"

    # What happens if we give NumericResponse a non-numeric input?
    {:ok, container, flow, block, _context} =
      FlowRunner.next_block(container, context, "not a number")

    assert resource_value(container, flow, context, block.config.prompt) ==
             "your name or age is either too long or not a number or something"

    # Ok let's give it real input again
    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context, "11")

    assert resource_value(container, flow, context, block.config.prompt) ==
             "i think we're done here"

    {:end, _container, _flow, _block,
     %{log: ["we are logging the mega test", "we are logging the mega test"]}} =
      FlowRunner.next_block(container, context)
  end
end
