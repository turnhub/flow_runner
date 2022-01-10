defmodule FlowRunnerTest do
  use ExUnit.Case, async: true
  import FlowRunner.Test.Utils
  doctest FlowRunner

  setup :with_flow_loader!

  @tag flow: "test/basic.flow"
  test "compile a flow", %{container: container} do
    assert container
  end

  @tag flow: "test/basic.flow"
  test "run a flow", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "62d0084d-e88f-48c3-ac64-7a15855f0a43", "eng", "TEXT")

    {:ok, _context, _, output} = FlowRunner.next_block(container, context)
    assert output.prompt.value == "welcome to this block"
    assert output.prompt.modes == ["TEXT"]
    assert output.prompt.content_type == "TEXT"
  end

  @tag flow: "test/selectoneresponse.flow"
  test "language selection with rc2", %{container: container} do
    {:ok, _context, _, output} =
      FlowRunner.next_block(
        container,
        %FlowRunner.Context{
          current_flow_uuid: "efaabaac-d035-43f5-a7fe-0e4e757c8095",
          language: "fra",
          mode: "TEXT"
        }
      )

    assert %{prompt: %{value: "اختر اسمًا"}} = output

    {:ok, _context, _, output} =
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

  @tag flow: "test/selectoneresponse.rc3.flow"
  test "language selection with rc3", %{container: container} do
    {:ok, _context, _, output} =
      FlowRunner.next_block(
        container,
        %FlowRunner.Context{
          current_flow_uuid: "efaabaac-d035-43f5-a7fe-0e4e757c8095",
          language: "fra",
          mode: "TEXT",
          vars: %{
            "contact" => %{"name" => "Jühn Døë"}
          }
        }
      )

    assert %{prompt: %{value: "اختر اسمًا"}} = output

    {:ok, _context, _, output} =
      FlowRunner.next_block(
        container,
        %FlowRunner.Context{
          current_flow_uuid: "efaabaac-d035-43f5-a7fe-0e4e757c8095",
          language: "eng",
          mode: "TEXT",
          vars: %{
            "contact" => %{"name" => "ÿühn ∂øë"}
          }
        }
      )

    # Note the correct capitalisation of Unicode characters
    assert %{prompt: %{value: "hi *Ÿühn ∂øë*! Choose a name:"}} = output
  end

  @tag flow: "test/selectoneresponse.rc3.flow"
  test "select one response", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(
        container,
        "efaabaac-d035-43f5-a7fe-0e4e757c8095",
        "fra",
        "TEXT",
        %{
          "contact" => %{"name" => "foo bar"}
        }
      )

    {:ok, context, _, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "اختر اسمًا"}} = output
    assert %{waiting_for_user_input: true} = context
    {:ok, context, _, output} = FlowRunner.next_block(container, context, "maalika")
    assert %{prompt: %{value: "salaam maalika"}} = output
    assert %{waiting_for_user_input: false} = context
    {:end, _context} = FlowRunner.next_block(container, context)

    {:ok, context} =
      FlowRunner.create_context(
        container,
        "efaabaac-d035-43f5-a7fe-0e4e757c8095",
        "eng",
        "TEXT",
        %{
          "contact" => %{"name" => "foo bar"}
        }
      )

    {:ok, context, _, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "hi *Foo Bar*! Choose a name:"}} = output
    assert %{waiting_for_user_input: true} = context
    {:ok, context, _, output} = FlowRunner.next_block(container, context, "yaseen")
    assert %{prompt: %{value: "hello yaseen"}} = output
    assert %{waiting_for_user_input: false} = context
    {:end, _context} = FlowRunner.next_block(container, context)
  end

  @tag flow: "test/selectoneresponse.flow"
  test "select one response with rc2", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "efaabaac-d035-43f5-a7fe-0e4e757c8095", "fra", "TEXT")

    {:ok, context, _, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "اختر اسمًا"}} = output
    assert %{waiting_for_user_input: true} = context
    {:ok, context, _, output} = FlowRunner.next_block(container, context, "maalika")
    assert %{prompt: %{value: "salaam maalika"}} = output
    assert %{waiting_for_user_input: false} = context
    {:end, _context} = FlowRunner.next_block(container, context)

    {:ok, context} =
      FlowRunner.create_context(container, "efaabaac-d035-43f5-a7fe-0e4e757c8095", "eng", "TEXT")

    {:ok, context, _, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "choose a name"}} = output
    assert %{waiting_for_user_input: true} = context
    {:ok, context, _, output} = FlowRunner.next_block(container, context, "yaseen")
    assert %{prompt: %{value: "hello yaseen"}} = output
    assert %{waiting_for_user_input: false} = context
    {:end, _context} = FlowRunner.next_block(container, context)
  end

  @tag flow: "test/selectoneresponse.rc3.flow"
  test "select one response with rc3", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(
        container,
        "efaabaac-d035-43f5-a7fe-0e4e757c8095",
        "fra",
        "TEXT",
        %{
          "contact" => %{"name" => "foo bar"}
        }
      )

    {:ok, context, _, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "اختر اسمًا"}} = output
    assert %{waiting_for_user_input: true} = context
    {:ok, context, _, output} = FlowRunner.next_block(container, context, "maalika")
    assert %{prompt: %{value: "salaam maalika"}} = output
    assert %{waiting_for_user_input: false} = context
    {:end, _context} = FlowRunner.next_block(container, context)

    {:ok, context} =
      FlowRunner.create_context(
        container,
        "efaabaac-d035-43f5-a7fe-0e4e757c8095",
        "eng",
        "TEXT",
        %{
          "contact" => %{"name" => "foo bar"}
        }
      )

    {:ok, context, _, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "hi *Foo Bar*! Choose a name:"}} = output
    assert %{waiting_for_user_input: true} = context
    {:ok, context, _, output} = FlowRunner.next_block(container, context, "yaseen")
    assert %{prompt: %{value: "hello yaseen"}} = output
    assert %{waiting_for_user_input: false} = context
    {:end, _context} = FlowRunner.next_block(container, context)
  end

  @tag flow: "test/runflow.flow"
  test "runflow block", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "f81559f9-1cf5-4125-abb0-4c88a1c4083f", "eng", "TEXT")

    {:ok, context, _, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "flow 1"}} = output
    {:ok, context, _, _output} = FlowRunner.next_block(container, context)
    {:ok, context, _, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "flow 2"}} = output
    {:ok, context, _, _output} = FlowRunner.next_block(container, context)
    {:ok, context, _, output} = FlowRunner.next_block(container, context)
    assert %{prompt: %{value: "back to flow 1"}} = output
    {:end, _context} = FlowRunner.next_block(container, context)
  end

  @tag flow: "test/log.flow"
  test "log block", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "912b53c1-de3c-4093-9d98-9bf25b9ad75a", "eng", "TEXT")

    {:ok, context, _, _output} = FlowRunner.next_block(container, context)
    {:ok, context, _, _output} = FlowRunner.next_block(container, context)
    {:end, context} = FlowRunner.next_block(container, context)

    assert context.log == ["block2", "block1"]
  end

  @tag flow: "test/case.flow"
  test "case block", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "289bb197-fc9e-44dc-ada2-a769a91bf416", "eng", "TEXT")

    context = %FlowRunner.Context{context | vars: %{patient_age: 19}}

    {:ok, context, _, _output} = FlowRunner.next_block(container, context)
    {:ok, context, _, _output} = FlowRunner.next_block(container, context)
    assert context.log == ["over age"]

    {:ok, context} =
      FlowRunner.create_context(container, "289bb197-fc9e-44dc-ada2-a769a91bf416", "eng", "TEXT")

    context = %FlowRunner.Context{
      context
      | vars: %{patient_age: 10}
    }

    {:ok, context, _, _output} = FlowRunner.next_block(container, context)
    {:ok, context, _, _output} = FlowRunner.next_block(container, context)
    assert context.log == ["under age"]
  end

  @tag flow: "test/set_contact_property.flow"
  test "set a contact property", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "62d0084d-e88f-48c3-ac64-7a15855f0a43", "eng", "TEXT")

    {:ok, context, _, output} = FlowRunner.next_block(container, context)

    assert %{
             contact_update_key: "name",
             contact_update_value: "yaseen"
           } = output

    {:ok, _context, _, output} = FlowRunner.next_block(container, context)

    assert %{
             contact_update_key: "name",
             contact_update_value: "aalia"
           } = output
  end

  @tag flow: "test/set_group_membership.flow"
  test "set group membership", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "62d0084d-e88f-48c3-ac64-7a15855f0a43", "eng", "TEXT")

    {:ok, context, _, output} = FlowRunner.next_block(container, context)

    assert %{
             group_update_key: "7294",
             group_update_is_member: true
           } = output

    {:ok, _context, _, output} = FlowRunner.next_block(container, context)

    assert %{
             group_update_key: "7294",
             group_update_is_member: false
           } = output
  end

  @tag flow: "test/numeric_response.flow"
  test "numeric response block invalid input", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "cc630cda-384e-41a3-9907-5262d23a6084", "eng", "TEXT")

    assert(
      {:ok, context, _, %{prompt: %{value: "what is your age"}}} =
        FlowRunner.next_block(container, context)
    )

    assert {:ok, _context, _, %{prompt: %{value: "please enter a numeric age between 5 and 80"}}} =
             FlowRunner.next_block(container, context, "yaseen")
  end

  @tag flow: "test/numeric_response.flow"
  test "numeric response ranges", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "cc630cda-384e-41a3-9907-5262d23a6084", "eng", "TEXT")

    assert(
      {:ok, context, _, %{prompt: %{value: "what is your age"}}} =
        FlowRunner.next_block(container, context)
    )

    assert {:ok, _context, _, %{prompt: %{value: "your age is not just right"}}} =
             FlowRunner.next_block(container, context, "5")

    assert {:ok, context, _,
            %{prompt: %{value: "your age is just right. enter any other number."}}} =
             FlowRunner.next_block(container, context, "32")

    # And now we test another NumericResponse but with no validation included.

    assert {:ok, _context, _, %{prompt: %{value: "please enter a numeric age between 5 and 80"}}} =
             FlowRunner.next_block(container, context, "jar")

    assert {:ok, _context, _, %{prompt: %{value: "end of flow"}}} =
             FlowRunner.next_block(container, context, "1")
  end

  @tag flow: "test/open_response.flow"
  test "open response block", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "6040838d-d16a-4f9d-9c3a-b611f078ae44", "eng", "SMS")

    assert {:ok, context, _, %{prompt: %{value: "say anything up to 10 characters long."}}} =
             FlowRunner.next_block(container, context)

    assert {:ok, context, _,
            %{prompt: %{value: "wow, ok! is so interesting. say even more things"}}} =
             FlowRunner.next_block(container, context, "ok!")

    assert {:ok, context, _, %{prompt: %{value: "done"}}} =
             FlowRunner.next_block(container, context, "even more things")

    assert {:end, _context} = FlowRunner.next_block(container, context)
  end
end
