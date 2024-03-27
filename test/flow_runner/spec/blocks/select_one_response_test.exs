defmodule FlowRunner.Spec.Blocks.SelectOneResponseTest do
  use ExUnit.Case
  import FlowRunner.Test.Utils
  alias FlowRunner.Spec.Blocks.SelectOneResponse

  setup :with_flow_loader!

  @tag flow: "test/buttons_then_routing.flow"
  test "evaluate_outgoing/5 selects the correct outgoing link when the user input is a string resembling a boolean",
       %{container: container} do
    [flow] = container.flows

    block = %FlowRunner.Spec.Block{
      uuid: "ddc1b3d7-f93f-513e-8990-5241821e700d",
      name: "ref_Buttons_7bef16",
      label: nil,
      semantic_label: nil,
      tags: [],
      type: "MobilePrimitives.SelectOneResponse",
      config: %{
        prompt: "aa9d2ff7-0db2-44f9-8074-aece760795a5",
        choices: [
          %{
            name: "True",
            prompt: "48e95d58-a623-46fd-93c7-0a2674111d1c",
            test: "block.response = \"True\""
          },
          %{
            name: "2",
            prompt: "ae97bb77-8f80-4b93-b51f-d7b1e96e5eeb",
            test: "block.response = \"2\""
          },
          %{
            name: "Button 3",
            prompt: "86271754-00e8-4f9f-bafb-68abdbb74350",
            test: "block.response = \"Button 3\""
          }
        ]
      },
      exits: [
        %FlowRunner.Spec.Exit{
          uuid: "bd90534c-7974-466a-a50d-532efd7104ea",
          name: "ref_Buttons_7bef16",
          destination_block: "528d89f0-7b69-5b93-9376-a6c41ac3ac22",
          semantic_label: "",
          test: "",
          default: true,
          config: %{},
          vendor_metadata: %{}
        }
      ]
    }

    context = %FlowRunner.Context{
      language: "eng",
      mode: "RICH_MESSAGING",
      log: [],
      waiting_for_user_input: true,
      current_flow_uuid: "9c0b42bf-ff0b-43f6-8423-2f7b6666efbd",
      last_block_uuid: "ddc1b3d7-f93f-513e-8990-5241821e700d",
      vars: %{
        "flow" => %{
          "__value__" => "9c0b42bf-ff0b-43f6-8423-2f7b6666efbd",
          "uuid" => "9c0b42bf-ff0b-43f6-8423-2f7b6666efbd"
        }
      },
      private: %{},
      finished: false,
      waiting_for_child_flow: false,
      child_flow_uuid: nil,
      parent_flow_uuid: nil,
      parent_state_uuid: nil
    }

    user_input = "True"

    assert {:ok, %{"__value__" => "True", "index" => 0, "label" => "True", "name" => "True"}} =
             SelectOneResponse.evaluate_outgoing(container, flow, block, context, user_input)
  end

  @tag flow: "test/buttons_then_routing.flow"
  test "evaluate_outgoing/5 selects the correct outgoing link when the user input is a string resembling a number",
       %{container: container} do
    [flow] = container.flows

    block = %FlowRunner.Spec.Block{
      uuid: "ddc1b3d7-f93f-513e-8990-5241821e700d",
      name: "ref_Buttons_7bef16",
      label: nil,
      semantic_label: nil,
      tags: [],
      type: "MobilePrimitives.SelectOneResponse",
      config: %{
        prompt: "aa9d2ff7-0db2-44f9-8074-aece760795a5",
        choices: [
          %{
            name: "True",
            prompt: "48e95d58-a623-46fd-93c7-0a2674111d1c",
            test: "block.response = \"True\""
          },
          %{
            name: "2",
            prompt: "ae97bb77-8f80-4b93-b51f-d7b1e96e5eeb",
            test: "block.response = \"2\""
          },
          %{
            name: "Button 3",
            prompt: "86271754-00e8-4f9f-bafb-68abdbb74350",
            test: "block.response = \"Button 3\""
          }
        ]
      },
      exits: [
        %FlowRunner.Spec.Exit{
          uuid: "bd90534c-7974-466a-a50d-532efd7104ea",
          name: "ref_Buttons_7bef16",
          destination_block: "528d89f0-7b69-5b93-9376-a6c41ac3ac22",
          semantic_label: "",
          test: "",
          default: true,
          config: %{},
          vendor_metadata: %{}
        }
      ]
    }

    context = %FlowRunner.Context{
      language: "eng",
      mode: "RICH_MESSAGING",
      log: [],
      waiting_for_user_input: true,
      current_flow_uuid: "9c0b42bf-ff0b-43f6-8423-2f7b6666efbd",
      last_block_uuid: "ddc1b3d7-f93f-513e-8990-5241821e700d",
      vars: %{
        "flow" => %{
          "__value__" => "9c0b42bf-ff0b-43f6-8423-2f7b6666efbd",
          "uuid" => "9c0b42bf-ff0b-43f6-8423-2f7b6666efbd"
        }
      },
      private: %{},
      finished: false,
      waiting_for_child_flow: false,
      child_flow_uuid: nil,
      parent_flow_uuid: nil,
      parent_state_uuid: nil
    }

    user_input = "2"

    assert {:ok, %{"__value__" => "2", "index" => 1, "label" => "2", "name" => "2"}} =
             SelectOneResponse.evaluate_outgoing(container, flow, block, context, user_input)
  end
end
