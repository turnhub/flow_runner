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

    {:ok, context} =
      FlowRunner.start_flow(container, "62d0084d-e88f-48c3-ac64-7a15855f0a43", "eng", "TEXT")

    {:ok, _context, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "welcome to this block"}} = output
  end

  test "language selection" do
    {:ok, container} =
      File.read!("test/selectoneresponse.flow")
      |> FlowRunner.compile()

    {:ok, _context, output} =
      FlowRunner.next_block(
        container,
        %FlowRunner.Context{
          current_flow_uuid: "efaabaac-d035-43f5-a7fe-0e4e757c8095",
          language: "fra",
          mode: "TEXT"
        }
      )

    assert %{prompt: %{value: "اختر اسمًا"}} = output

    {:ok, _context, output} =
      FlowRunner.next_block(
        container,
        %FlowRunner.Context{
          current_flow_uuid: "efaabaac-d035-43f5-a7fe-0e4e757c8095",
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

    {:ok, context} =
      FlowRunner.start_flow(container, "efaabaac-d035-43f5-a7fe-0e4e757c8095", "fra", "TEXT")

    {:ok, context, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "اختر اسمًا"}} = output
    assert %{waiting_for_user_input: true} = context
    {:ok, context, output} = FlowRunner.next_block(container, context, "maalika")
    assert %{prompt: %{value: "salaam maalika"}} = output
    assert %{waiting_for_user_input: false} = context
    {:end, _context} = FlowRunner.next_block(container, context)

    {:ok, context} =
      FlowRunner.start_flow(container, "efaabaac-d035-43f5-a7fe-0e4e757c8095", "eng", "TEXT")

    {:ok, context, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "choose a name"}} = output
    assert %{waiting_for_user_input: true} = context
    {:ok, context, output} = FlowRunner.next_block(container, context, "yaseen")
    assert %{prompt: %{value: "hello yaseen"}} = output
    assert %{waiting_for_user_input: false} = context
    {:end, _context} = FlowRunner.next_block(container, context)
  end

  test "runflow block" do
    {:ok, container} =
      File.read!("test/runflow.flow")
      |> FlowRunner.compile()

    {:ok, context} =
      FlowRunner.start_flow(container, "f81559f9-1cf5-4125-abb0-4c88a1c4083f", "eng", "TEXT")

    {:ok, context, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "flow 1"}} = output
    {:ok, context, _output} = FlowRunner.next_block(container, context)
    {:ok, context, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "flow 2"}} = output
    {:ok, context, _output} = FlowRunner.next_block(container, context)
    {:ok, context, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "back to flow 1"}} = output
    {:end, _context} = FlowRunner.next_block(container, context)
  end

  test "log block" do
    {:ok, container} =
      File.read!("test/log.flow")
      |> FlowRunner.compile()

    {:ok, context} =
      FlowRunner.start_flow(container, "912b53c1-de3c-4093-9d98-9bf25b9ad75a", "eng", "TEXT")

    {:ok, context, _output} = FlowRunner.next_block(container, context)
    {:ok, context, _output} = FlowRunner.next_block(container, context)
    {:end, context} = FlowRunner.next_block(container, context)

    assert context.log == ["block2", "block1"]
  end

  test "case block" do
    {:ok, container} =
      File.read!("test/case.flow")
      |> FlowRunner.compile()

    {:ok, context} =
      FlowRunner.start_flow(container, "289bb197-fc9e-44dc-ada2-a769a91bf416", "eng", "TEXT")

    context = %FlowRunner.Context{context | vars: %{patient_age: 19}}

    {:ok, context, _output} = FlowRunner.next_block(container, context)
    {:ok, context, _output} = FlowRunner.next_block(container, context)
    assert context.log == ["over age"]

    {:ok, context} =
      FlowRunner.start_flow(container, "289bb197-fc9e-44dc-ada2-a769a91bf416", "eng", "TEXT")

    context = %FlowRunner.Context{
      context
      | vars: %{patient_age: 10}
    }

    {:ok, context, _output} = FlowRunner.next_block(container, context)
    {:ok, context, _output} = FlowRunner.next_block(container, context)
    assert context.log == ["under age"]
  end

  test "set a contact property" do
    {:ok, container} =
      File.read!("test/set_contact_property.flow")
      |> FlowRunner.compile()

    {:ok, context} =
      FlowRunner.start_flow(container, "62d0084d-e88f-48c3-ac64-7a15855f0a43", "eng", "TEXT")

    {:ok, context, output} = FlowRunner.next_block(container, context)

    assert %{
             contact_update_key: "name",
             contact_update_value: "yaseen"
           } = output

    {:ok, _context, output} = FlowRunner.next_block(container, context)

    assert %{
             contact_update_key: "name",
             contact_update_value: "aalia"
           } = output
  end

  test "set group membership" do
    {:ok, container} =
      File.read!("test/set_group_membership.flow")
      |> FlowRunner.compile()

    {:ok, context} =
      FlowRunner.start_flow(container, "62d0084d-e88f-48c3-ac64-7a15855f0a43", "eng", "TEXT")

    {:ok, context, output} = FlowRunner.next_block(container, context)

    assert %{
             group_update_key: "7294",
             group_update_is_member: true
           } = output

    {:ok, _context, output} = FlowRunner.next_block(container, context)

    assert %{
             group_update_key: "7294",
             group_update_is_member: false
           } = output
  end
end
