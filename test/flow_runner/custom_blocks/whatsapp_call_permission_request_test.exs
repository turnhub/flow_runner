defmodule FlowRunner.CustomBlocks.WhatsAppCallPermissionRequestTest do
  use ExUnit.Case, async: true

  alias FlowRunner.CustomBlocks.WhatsAppCallPermissionRequest

  describe "validate_config!/1" do
    test "returns call_permission_request config with required text parameter" do
      config = %{
        "call_permission_request" => %{
          "text" => "Can we call you to assist?"
        }
      }

      result = WhatsAppCallPermissionRequest.validate_config!(config)

      assert result.call_permission_request.text == "Can we call you to assist?"
    end

    test "raises error when call_permission_request key is missing" do
      config = %{}

      assert_raise FunctionClauseError, fn ->
        WhatsAppCallPermissionRequest.validate_config!(config)
      end
    end

    test "raises error when text parameter is missing" do
      config = %{
        "call_permission_request" => %{}
      }

      assert_raise FunctionClauseError, fn ->
        WhatsAppCallPermissionRequest.validate_config!(config)
      end
    end
  end

  describe "evaluate_incoming/4" do
    test "sets waiting_for_user_input to true and updates last_block_uuid" do
      container = %{}
      flow = %{}
      block = %{uuid: "test-block-uuid"}

      context = %{
        last_block_uuid: "previous-uuid",
        waiting_for_user_input: false
      }

      {:ok, returned_container, returned_flow, returned_block, returned_context} =
        WhatsAppCallPermissionRequest.evaluate_incoming(container, flow, block, context)

      assert returned_container == container
      assert returned_flow == flow
      assert returned_block == block
      assert returned_context.last_block_uuid == "test-block-uuid"
      assert returned_context.waiting_for_user_input == true
    end
  end

  describe "evaluate_outgoing/5" do
    test "returns user input unchanged" do
      container = %{}
      flow = %{}
      block = %{}
      context = %{}
      user_input = %{type: "interactive", call_permission_reply: %{"response" => "accept"}}

      {:ok, returned_input} =
        WhatsAppCallPermissionRequest.evaluate_outgoing(
          container,
          flow,
          block,
          context,
          user_input
        )

      assert returned_input == user_input
    end

    test "returns user input unchanged for different input types" do
      container = %{}
      flow = %{}
      block = %{}
      context = %{}

      test_inputs = [
        %{type: "interactive", call_permission_reply: %{"response" => "accept"}},
        %{type: "interactive", call_permission_reply: %{"response" => "reject"}}
      ]

      for input <- test_inputs do
        {:ok, returned_input} =
          WhatsAppCallPermissionRequest.evaluate_outgoing(container, flow, block, context, input)

        assert returned_input == input
      end
    end
  end
end
