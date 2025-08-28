defmodule FlowRunner.CustomBlocks.WhatsAppRequestLocationTest do
  use ExUnit.Case, async: true

  alias FlowRunner.CustomBlocks.WhatsAppRequestLocation

  describe "validate_config!/1" do
    test "returns request_location config with required text parameter" do
      config = %{
        "request_location" => %{
          "text" => "Please share your location so we can help you better."
        }
      }

      result = WhatsAppRequestLocation.validate_config!(config)

      assert result.request_location.text ==
               "Please share your location so we can help you better."
    end

    test "raises error when request_location key is missing" do
      config = %{}

      assert_raise FunctionClauseError, fn ->
        WhatsAppRequestLocation.validate_config!(config)
      end
    end

    test "raises error when text parameter is missing" do
      config = %{
        "request_location" => %{}
      }

      assert_raise FunctionClauseError, fn ->
        WhatsAppRequestLocation.validate_config!(config)
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
        WhatsAppRequestLocation.evaluate_incoming(container, flow, block, context)

      assert returned_container == container
      assert returned_flow == flow
      assert returned_block == block
      assert returned_context.last_block_uuid == "test-block-uuid"
      assert returned_context.waiting_for_user_input == true
    end

    test "preserves other context fields while updating specific ones" do
      container = %{}
      flow = %{}
      block = %{uuid: "location-block-uuid"}

      context = %{
        last_block_uuid: "old-uuid",
        waiting_for_user_input: false,
        some_other_field: "preserved_value",
        another_field: 42
      }

      {:ok, _container, _flow, _block, returned_context} =
        WhatsAppRequestLocation.evaluate_incoming(container, flow, block, context)

      assert returned_context.last_block_uuid == "location-block-uuid"
      assert returned_context.waiting_for_user_input == true
      assert returned_context.some_other_field == "preserved_value"
      assert returned_context.another_field == 42
    end
  end

  describe "evaluate_outgoing/5" do
    test "returns user input unchanged" do
      container = %{}
      flow = %{}
      block = %{}
      context = %{}
      user_input = %{type: "location", lat: 40.7128, lng: -74.0060}

      {:ok, returned_input} =
        WhatsAppRequestLocation.evaluate_outgoing(container, flow, block, context, user_input)

      assert returned_input == user_input
    end

    test "returns user input unchanged for different input types" do
      container = %{}
      flow = %{}
      block = %{}
      context = %{}

      test_inputs = [
        %{type: "text", value: "hello"},
        %{type: "location", lat: 40.7128, lng: -74.0060},
        %{type: "image", url: "http://example.com/image.jpg"},
        nil
      ]

      for input <- test_inputs do
        {:ok, returned_input} =
          WhatsAppRequestLocation.evaluate_outgoing(container, flow, block, context, input)

        assert returned_input == input
      end
    end
  end
end
