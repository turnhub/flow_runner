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
      FlowRunner.create_context(
        container,
        "62d0084d-e88f-48c3-ac64-7a15855f0a43",
        "eng",
        "TEXT"
      )

    assert {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)

    assert resource_value(container, flow, context, block.config.prompt) ==
             "welcome to this block"
  end

  @tag flow: "test/selectoneresponse.flow"
  test "language selection with rc2", %{container: container} do
    {:ok, container, flow, block, context} =
      FlowRunner.next_block(
        container,
        %FlowRunner.Context{
          current_flow_uuid: "efaabaac-d035-43f5-a7fe-0e4e757c8095",
          language: "fra",
          mode: "TEXT"
        }
      )

    assert resource_value(container, flow, context, block.config.prompt) ==
             "اختر اسمًا"

    {:ok, container, flow, block, context} =
      FlowRunner.next_block(
        container,
        %FlowRunner.Context{
          current_flow_uuid: "efaabaac-d035-43f5-a7fe-0e4e757c8095",
          language: "eng",
          mode: "TEXT"
        }
      )

    assert resource_value(container, flow, context, block.config.prompt) == "choose a name"
  end

  @tag flow: "test/selectoneresponse.rc3.flow"
  test "language selection with rc3", %{container: container} do
    {:ok, container, flow, block, context} =
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

    assert resource_value(container, flow, context, block.config.prompt) == "اختر اسمًا"

    {:ok, container, flow, block, context} =
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

    assert resource_value(container, flow, context, block.config.prompt) ==
             "hi *@PROPER(contact.name)*! Choose a name:"
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

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)
    assert resource_value(container, flow, context, block.config.prompt) == "اختر اسمًا"
    assert context.waiting_for_user_input

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context, "maalika")
    assert %{prompt: resource_uuid} = block.config
    assert resource_value(container, flow, context, resource_uuid) == "salaam maalika"
    refute context.waiting_for_user_input

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

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)
    assert %{prompt: resource_uuid} = block.config

    assert resource_value(container, flow, context, resource_uuid) ==
             "hi *@PROPER(contact.name)*! Choose a name:"

    assert context.waiting_for_user_input
    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context, "yaseen")

    assert %{prompt: resource_uuid} = block.config
    assert resource_value(container, flow, context, resource_uuid) == "hello yaseen"

    refute context.waiting_for_user_input
    {:end, _context} = FlowRunner.next_block(container, context)
  end

  @tag flow: "test/selectoneresponse.flow"
  test "select one response with rc2", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "efaabaac-d035-43f5-a7fe-0e4e757c8095", "fra", "TEXT")

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)
    assert resource_value(container, flow, context, block.config.prompt) == "اختر اسمًا"
    assert context.waiting_for_user_input

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context, "maalika")
    assert resource_value(container, flow, context, block.config.prompt) == "salaam maalika"
    refute context.waiting_for_user_input

    {:end, _context} = FlowRunner.next_block(container, context)

    {:ok, context} =
      FlowRunner.create_context(container, "efaabaac-d035-43f5-a7fe-0e4e757c8095", "eng", "TEXT")

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)
    assert resource_value(container, flow, context, block.config.prompt) == "choose a name"
    assert context.waiting_for_user_input

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context, "yaseen")
    assert resource_value(container, flow, context, block.config.prompt) == "hello yaseen"
    refute context.waiting_for_user_input

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

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)
    assert resource_value(container, flow, context, block.config.prompt) == "اختر اسمًا"
    assert context.waiting_for_user_input

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context, "maalika")
    assert resource_value(container, flow, context, block.config.prompt) == "salaam maalika"
    refute context.waiting_for_user_input

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

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)

    assert resource_value(container, flow, context, block.config.prompt) ==
             "hi *@PROPER(contact.name)*! Choose a name:"

    assert context.waiting_for_user_input

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context, "yaseen")
    assert resource_value(container, flow, context, block.config.prompt) == "hello yaseen"
    refute context.waiting_for_user_input

    {:end, _context} = FlowRunner.next_block(container, context)
  end

  @tag flow: "test/selectoneresponse.rc3.flow"
  test "select one response with rc3 and unexpected response", %{container: container} do
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

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)
    assert resource_value(container, flow, context, block.config.prompt) == "اختر اسمًا"
    assert context.waiting_for_user_input

    {:end, context} = FlowRunner.next_block(container, context, "something unexpected")

    assert context.vars["choose"] == "something unexpected"
    assert context.vars["block"]["value"] == "something unexpected"
  end

  @tag flow: "test/runflow.flow"
  test "runflow block", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "f81559f9-1cf5-4125-abb0-4c88a1c4083f", "eng", "TEXT")

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)
    assert resource_value(container, flow, context, block.config.prompt) == "flow 1"
    # assert %{prompt: %{value: "flow 1"}} = output

    {:ok, container, _flow, _block, context} = FlowRunner.next_block(container, context)
    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)

    assert resource_value(container, flow, context, block.config.prompt) == "flow 2"

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)
    assert resource_value(container, flow, context, block.config.prompt) == "back to flow 1"
    {:end, _current_block, _context} = FlowRunner.next_block(container, context)
  end

  @tag flow: "test/log.flow"
  test "log block", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "912b53c1-de3c-4093-9d98-9bf25b9ad75a", "eng", "TEXT")

    {:ok, container, _flow, _block, context} = FlowRunner.next_block(container, context)
    {:ok, container, _flow, _block, context} = FlowRunner.next_block(container, context)
    {:end, _current_block, context} = FlowRunner.next_block(container, context)

    assert context.log == ["block2", "block1"]
  end

  @tag flow: "test/case.flow"
  test "case block", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "289bb197-fc9e-44dc-ada2-a769a91bf416", "eng", "TEXT")

    context = %FlowRunner.Context{context | vars: %{patient_age: 19}}

    {:ok, container, _flow, _block, context} = FlowRunner.next_block(container, context)
    {:ok, container, _flow, _block, context} = FlowRunner.next_block(container, context)

    assert context.log == ["over age"]

    {:ok, context} =
      FlowRunner.create_context(container, "289bb197-fc9e-44dc-ada2-a769a91bf416", "eng", "TEXT")

    context = %FlowRunner.Context{
      context
      | vars: %{patient_age: 10}
    }

    {:ok, container, _flow, _block, context} = FlowRunner.next_block(container, context)
    {:ok, _container, _flow, _block, context} = FlowRunner.next_block(container, context)
    assert context.log == ["under age"]
  end

  @tag flow: "test/set_contact_property.flow"
  test "set a contact property", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "62d0084d-e88f-48c3-ac64-7a15855f0a43", "eng", "TEXT")

    {:ok, container, _flow, block, context} = FlowRunner.next_block(container, context)

    assert %{
             set_contact_property: %{
               property_key: "name",
               property_value: "yaseen"
             }
           } = block.config

    {:ok, _container, _flow, block, _context} = FlowRunner.next_block(container, context)

    assert %{
             set_contact_property: %{
               property_key: "name",
               property_value: "aalia"
             }
           } = block.config
  end

  @tag flow: "test/set_group_membership.flow"
  test "set group membership", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "62d0084d-e88f-48c3-ac64-7a15855f0a43", "eng", "TEXT")

    {:ok, container, _flow, block, context} = FlowRunner.next_block(container, context)

    assert %{
             group_key: "7294",
             group_name: "Healthcare workers",
             is_member: true
           } = block.config

    {:ok, _container, _flow, block, _context} = FlowRunner.next_block(container, context)

    assert %{
             group_key: "7294",
             group_name: nil,
             is_member: false
           } = block.config
  end

  @tag flow: "test/numeric_response.flow"
  test "numeric response block invalid input", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "cc630cda-384e-41a3-9907-5262d23a6084", "eng", "TEXT")

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)
    assert resource_value(container, flow, context, block.config.prompt) == "what is your age"

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context, "yaseen")

    assert resource_value(container, flow, context, block.config.prompt) ==
             "please enter a numeric age between 5 and 80"

    assert context.vars["prompt_number"] == "yaseen"
    assert context.vars["block"]["value"] == "yaseen"
  end

  @tag flow: "test/numeric_response.flow"
  test "numeric response ranges", %{container: container} do
    # NOTE that for some of these tests, we're re-using the original context.
    #      Whe ignored the updated context at times by prefixing it with `_`

    {:ok, context} =
      FlowRunner.create_context(container, "cc630cda-384e-41a3-9907-5262d23a6084", "eng", "TEXT")

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)
    assert resource_value(container, flow, context, block.config.prompt) == "what is your age"

    {:ok, container, flow, block, _context} = FlowRunner.next_block(container, context, "5")

    assert resource_value(container, flow, context, block.config.prompt) ==
             "your age is not just right"

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context, "32")

    assert resource_value(container, flow, context, block.config.prompt) ==
             "your age is just right. enter any other number."

    # And now we test another NumericResponse but with no validation included.

    {:ok, container, flow, block, _context} = FlowRunner.next_block(container, context, "jar")

    assert resource_value(container, flow, context, block.config.prompt) ==
             "please enter a numeric age between 5 and 80"

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context, "1")

    assert resource_value(container, flow, context, block.config.prompt) ==
             "end of flow"
  end

  @tag flow: "test/open_response.flow"
  test "open response block", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(container, "6040838d-d16a-4f9d-9c3a-b611f078ae44", "eng", "SMS")

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)

    assert resource_value(container, flow, context, block.config.prompt) ==
             "say anything up to 10 characters long."

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context, "ok!")

    assert resource_value(container, flow, context, block.config.prompt) ==
             "wow, @(block.value) is so interesting. say even more things"

    {:ok, container, flow, block, context} =
      FlowRunner.next_block(container, context, "even more things")

    assert resource_value(container, flow, context, block.config.prompt) ==
             "done"

    assert {:end, _current_block, _context} = FlowRunner.next_block(container, context)
  end
end
