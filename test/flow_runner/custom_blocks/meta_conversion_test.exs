defmodule FlowRunner.CustomBlocks.MetaConversionTest do
  use ExUnit.Case, async: true

  alias FlowRunner.CustomBlocks.MetaConversion

  describe "validate_config!/1" do
    test "returns conversion config with required parameters only" do
      config = %{
        "conversion" => %{
          "event_name" => "Purchase",
          "user_data" => %{"email" => "user@example.com"}
        }
      }

      result = MetaConversion.validate_config!(config)

      assert result.conversion.event_name == "Purchase"
      assert result.conversion.user_data == %{"email" => "user@example.com"}
      assert result.conversion.optional_fields == %{}
    end

    test "returns conversion config with user_data and optional_fields as maps" do
      config = %{
        "conversion" => %{
          "event_name" => "AddToCart",
          "user_data" => %{"email" => "@email", "phone" => "@phone"},
          "optional_fields" => %{"event_id" => "123", "event_source_url" => "@url"}
        }
      }

      result = MetaConversion.validate_config!(config)

      assert result.conversion.event_name == "AddToCart"
      assert result.conversion.user_data == %{"email" => "@email", "phone" => "@phone"}

      assert result.conversion.optional_fields == %{
               "event_id" => "123",
               "event_source_url" => "@url"
             }
    end

    test "returns conversion config with user_data and optional_fields as keyword lists" do
      config = %{
        "conversion" => %{
          "event_name" => "ViewContent",
          "user_data" => [phone: "+1234567890", email: "test@example.com"],
          "optional_fields" => [event_id: "456", currency: "USD"]
        }
      }

      result = MetaConversion.validate_config!(config)

      assert result.conversion.event_name == "ViewContent"
      # Keyword lists are passed through as-is, conversion happens in simulator
      assert result.conversion.user_data == [phone: "+1234567890", email: "test@example.com"]
      assert result.conversion.optional_fields == [event_id: "456", currency: "USD"]
    end

    test "raises error when conversion key is missing" do
      config = %{}

      assert_raise FunctionClauseError, fn ->
        MetaConversion.validate_config!(config)
      end
    end

    test "raises error when event_name parameter is missing" do
      config = %{
        "conversion" => %{
          "user_data" => %{"email" => "user@example.com"}
        }
      }

      assert_raise FunctionClauseError, fn ->
        MetaConversion.validate_config!(config)
      end
    end

    test "raises error when user_data parameter is missing" do
      config = %{
        "conversion" => %{
          "event_name" => "Purchase"
        }
      }

      assert_raise FunctionClauseError, fn ->
        MetaConversion.validate_config!(config)
      end
    end

    test "returns conversion config with user_data and optional_fields as JSON strings" do
      config = %{
        "conversion" => %{
          "event_name" => "Purchase",
          "user_data" => "{\"email\":\"user@example.com\",\"phone\":\"+1234567890\"}",
          "optional_fields" => "{\"event_id\":\"123\",\"currency\":\"USD\"}"
        }
      }

      result = MetaConversion.validate_config!(config)

      assert result.conversion.event_name == "Purchase"
      # JSON strings are passed through as-is, conversion happens in simulator
      assert result.conversion.user_data ==
               "{\"email\":\"user@example.com\",\"phone\":\"+1234567890\"}"

      assert result.conversion.optional_fields == "{\"event_id\":\"123\",\"currency\":\"USD\"}"
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
        MetaConversion.evaluate_incoming(container, flow, block, context)

      assert returned_container == container
      assert returned_flow == flow
      assert returned_block == block
      assert returned_context.last_block_uuid == "test-block-uuid"
      assert returned_context.waiting_for_user_input == false
    end

    test "preserves other context fields while updating specific ones" do
      container = %{}
      flow = %{}
      block = %{uuid: "meta-conversion-block-uuid"}

      context = %{
        last_block_uuid: "old-uuid",
        waiting_for_user_input: true,
        some_other_field: "preserved_value",
        another_field: 42
      }

      {:ok, _container, _flow, _block, returned_context} =
        MetaConversion.evaluate_incoming(container, flow, block, context)

      assert returned_context.last_block_uuid == "meta-conversion-block-uuid"
      assert returned_context.waiting_for_user_input == false
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
      user_input = %{type: "text", value: "some user response"}

      {:ok, returned_input} =
        MetaConversion.evaluate_outgoing(container, flow, block, context, user_input)

      assert returned_input == user_input
    end

    test "returns user input unchanged for different input types" do
      container = %{}
      flow = %{}
      block = %{}
      context = %{}

      test_inputs = [
        %{type: "text", value: "hello"},
        %{type: "image", url: "http://example.com/image.jpg"},
        %{type: "location", lat: 40.7128, lng: -74.006},
        nil
      ]

      for input <- test_inputs do
        {:ok, returned_input} =
          MetaConversion.evaluate_outgoing(container, flow, block, context, input)

        assert returned_input == input
      end
    end
  end
end
