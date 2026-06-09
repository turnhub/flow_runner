defmodule FlowRunner.CustomBlocks.WhatsAppVideoCallRequestTest do
  use ExUnit.Case, async: true

  alias FlowRunner.CustomBlocks.WhatsAppVideoCallRequest

  describe "validate_config!/1" do
    test "returns video_call_request config with required text and optional display_text" do
      config = %{
        "video_call_request" => %{
          "text" => "Tap below to call us",
          "display_text" => "Call support"
        }
      }

      result = WhatsAppVideoCallRequest.validate_config!(config)

      assert result.video_call_request.text == "Tap below to call us"
      assert result.video_call_request.display_text == "Call support"
    end

    test "returns nil display_text when omitted" do
      config = %{
        "video_call_request" => %{
          "text" => "Tap below to call us"
        }
      }

      result = WhatsAppVideoCallRequest.validate_config!(config)

      assert result.video_call_request.text == "Tap below to call us"
      assert result.video_call_request.display_text == nil
    end

    test "raises error when video_call_request key is missing" do
      config = %{}

      assert_raise FunctionClauseError, fn ->
        WhatsAppVideoCallRequest.validate_config!(config)
      end
    end

    test "raises error when text parameter is missing" do
      config = %{
        "video_call_request" => %{}
      }

      assert_raise FunctionClauseError, fn ->
        WhatsAppVideoCallRequest.validate_config!(config)
      end
    end
  end

  describe "evaluate_incoming/4" do
    test "sets waiting_for_user_input to false and updates last_block_uuid" do
      container = %{}
      flow = %{}
      block = %{uuid: "test-block-uuid"}

      context = %{
        last_block_uuid: "previous-uuid",
        waiting_for_user_input: true
      }

      {:ok, returned_container, returned_flow, returned_block, returned_context} =
        WhatsAppVideoCallRequest.evaluate_incoming(container, flow, block, context)

      assert returned_container == container
      assert returned_flow == flow
      assert returned_block == block
      assert returned_context.last_block_uuid == "test-block-uuid"
      assert returned_context.waiting_for_user_input == false
    end
  end

  describe "evaluate_outgoing/5" do
    test "returns user input unchanged" do
      container = %{}
      flow = %{}
      block = %{}
      context = %{}
      user_input = %{type: "interactive"}

      {:ok, returned_input} =
        WhatsAppVideoCallRequest.evaluate_outgoing(container, flow, block, context, user_input)

      assert returned_input == user_input
    end
  end
end
