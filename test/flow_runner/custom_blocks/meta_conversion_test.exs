defmodule FlowRunner.CustomBlocks.MetaConversionTest do
  use ExUnit.Case, async: true

  alias FlowRunner.CustomBlocks.MetaConversion

  describe "validate_config!/1" do
    test "returns meta_conversion config with required parameters" do
      config = %{
        "meta_conversion" => %{
          "event_name" => "Purchase",
          "user_data" => %{"email" => "user@example.com"}
        }
      }

      result = MetaConversion.validate_config!(config)

      assert result.meta_conversion.event_name == "Purchase"
      assert result.meta_conversion.user_data == %{"email" => "user@example.com"}
      refute Map.has_key?(result.meta_conversion, :custom_data)
      refute Map.has_key?(result.meta_conversion, :event_time)
    end

    test "returns meta_conversion config with required and optional parameters" do
      config = %{
        "meta_conversion" => %{
          "event_name" => "AddToCart",
          "user_data" => %{"email" => "test@example.com", "phone" => "+1234567890"},
          "custom_data" => %{"value" => 99.99, "currency" => "USD"},
          "event_time" => "1234567890",
          "action_source" => "website"
        }
      }

      result = MetaConversion.validate_config!(config)

      assert result.meta_conversion.event_name == "AddToCart"

      assert result.meta_conversion.user_data == %{
               "email" => "test@example.com",
               "phone" => "+1234567890"
             }

      assert result.meta_conversion.custom_data == %{"value" => 99.99, "currency" => "USD"}
      assert result.meta_conversion.event_time == "1234567890"
      assert result.meta_conversion.action_source == "website"
    end

    test "returns meta_conversion config with all optional parameters" do
      config = %{
        "meta_conversion" => %{
          "event_name" => "Lead",
          "user_data" => %{"email" => "lead@example.com"},
          "custom_data" => %{"content_name" => "Product A"},
          "event_time" => "1234567890",
          "action_source" => "app",
          "event_source_url" => "https://example.com/product",
          "opt_out" => false,
          "event_id" => "event-123",
          "data_processing_options" => ["LDU"],
          "data_processing_options_country" => 1,
          "data_processing_options_state" => 1000
        }
      }

      result = MetaConversion.validate_config!(config)

      assert result.meta_conversion.event_name == "Lead"
      assert result.meta_conversion.user_data == %{"email" => "lead@example.com"}
      assert result.meta_conversion.custom_data == %{"content_name" => "Product A"}
      assert result.meta_conversion.event_time == "1234567890"
      assert result.meta_conversion.action_source == "app"
      assert result.meta_conversion.event_source_url == "https://example.com/product"
      assert result.meta_conversion.opt_out == false
      assert result.meta_conversion.event_id == "event-123"
      assert result.meta_conversion.data_processing_options == ["LDU"]
      assert result.meta_conversion.data_processing_options_country == 1
      assert result.meta_conversion.data_processing_options_state == 1000
    end

    test "raises error when meta_conversion key is missing" do
      config = %{}

      assert_raise FunctionClauseError, fn ->
        MetaConversion.validate_config!(config)
      end
    end

    test "raises error when event_name parameter is missing" do
      config = %{
        "meta_conversion" => %{
          "user_data" => %{"email" => "user@example.com"}
        }
      }

      assert_raise FunctionClauseError, fn ->
        MetaConversion.validate_config!(config)
      end
    end

    test "raises error when user_data parameter is missing" do
      config = %{
        "meta_conversion" => %{
          "event_name" => "Purchase"
        }
      }

      assert_raise FunctionClauseError, fn ->
        MetaConversion.validate_config!(config)
      end
    end

    test "raises error when event_name is not a string" do
      config = %{
        "meta_conversion" => %{
          "event_name" => 123,
          "user_data" => %{"email" => "user@example.com"}
        }
      }

      assert_raise FunctionClauseError, fn ->
        MetaConversion.validate_config!(config)
      end
    end

    test "raises error when user_data is not a map" do
      config = %{
        "meta_conversion" => %{
          "event_name" => "Purchase",
          "user_data" => "not a map"
        }
      }

      assert_raise FunctionClauseError, fn ->
        MetaConversion.validate_config!(config)
      end
    end
  end

  describe "validate_config!/1 with arbitrary optional parameters" do
    test "accepts any optional parameter beyond required fields" do
      config = %{
        "meta_conversion" => %{
          "event_name" => "Purchase",
          "user_data" => %{"email" => "user@example.com"},
          "arbitrary_field_1" => "value1",
          "arbitrary_field_2" => %{"nested" => "value"},
          "arbitrary_field_3" => 123
        }
      }

      result = MetaConversion.validate_config!(config)

      assert result.meta_conversion.event_name == "Purchase"
      assert result.meta_conversion.user_data == %{"email" => "user@example.com"}
      assert result.meta_conversion.arbitrary_field_1 == "value1"
      assert result.meta_conversion.arbitrary_field_2 == %{"nested" => "value"}
      assert result.meta_conversion.arbitrary_field_3 == 123
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
