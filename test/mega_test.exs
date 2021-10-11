defmodule MegaTest do
  use ExUnit.Case
  doctest FlowRunner

  test "compile a flow" do
    {:ok, container} =
      File.read!("test/mega_test.flow")
      |> FlowRunner.compile()

    {:error, "no matching flow"} =
      FlowRunner.start_flow(container, "62d0084d-e88f-48c3-ac64-7a15855f0a43", "eng", "TEXT")

    {:ok, context} =
      FlowRunner.start_flow(container, "ee84b2b7-ca0f-4492-a964-fdc5eb83dd47", "eng", "TEXT")

    {:ok, context, _, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "welcome to the MEGA test"}} = output

    {:ok, context, _, output} = FlowRunner.next_block(container, context)

    assert %{
             prompt: %{
               value: "do you want to CONTINUE or START AGAIN"
             },
             choices: %{"continue" => _, "start_again" => _}
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

    # And then a valid response
    {:ok, context, _, output} = FlowRunner.next_block(container, context, "yaseen")

    assert %{prompt: %{value: "yaseen what is your age?"}} = output
  end
end
