defmodule FlowRunner.CustomBlocks.WhatsAppCatalogTest do
  use ExUnit.Case, async: true

  alias FlowRunner.CustomBlocks.WhatsAppCatalog

  describe "validate_config!/1" do
    test "returns catalog config with required text parameter" do
      config = %{
        "catalog" => %{
          "text" => "Welcome to our catalog! Browse our products below."
        }
      }

      result = WhatsAppCatalog.validate_config!(config)

      assert result.catalog.text == "Welcome to our catalog! Browse our products below."
      refute Map.has_key?(result.catalog, :footer)
    end

    test "returns catalog config with text and optional footer parameter" do
      config = %{
        "catalog" => %{
          "text" => "Check out our latest products!",
          "footer" => "Contact us for more information"
        }
      }

      result = WhatsAppCatalog.validate_config!(config)

      assert result.catalog.text == "Check out our latest products!"
      assert result.catalog.footer == "Contact us for more information"
    end

    test "raises error when catalog key is missing" do
      config = %{}

      assert_raise FunctionClauseError, fn ->
        WhatsAppCatalog.validate_config!(config)
      end
    end

    test "raises error when text parameter is missing" do
      config = %{
        "catalog" => %{
          "footer" => "Some footer text"
        }
      }

      assert_raise FunctionClauseError, fn ->
        WhatsAppCatalog.validate_config!(config)
      end
    end
  end

  describe "read_optional_params/2" do
    test "returns empty map when no optional parameters are present" do
      params = %{"text" => "some text"}
      keys = [:footer, :header]

      result = WhatsAppCatalog.read_optional_params(params, keys)

      assert result == %{}
    end

    test "returns map with only present optional parameters" do
      params = %{
        "text" => "some text",
        "footer" => "footer text"
      }
      keys = [:footer, :header]

      result = WhatsAppCatalog.read_optional_params(params, keys)

      assert result == %{footer: "footer text"}
    end

    test "returns map with all optional parameters when present" do
      params = %{
        "text" => "some text",
        "footer" => "footer text",
        "header" => "header text"
      }
      keys = [:footer, :header]

      result = WhatsAppCatalog.read_optional_params(params, keys)

      assert result == %{footer: "footer text", header: "header text"}
    end

    test "converts string keys to atom keys" do
      params = %{
        "footer" => "footer value",
        "custom_param" => "custom value"
      }
      keys = [:footer, :custom_param]

      result = WhatsAppCatalog.read_optional_params(params, keys)

      assert result == %{footer: "footer value", custom_param: "custom value"}
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
        WhatsAppCatalog.evaluate_incoming(container, flow, block, context)

      assert returned_container == container
      assert returned_flow == flow
      assert returned_block == block
      assert returned_context.last_block_uuid == "test-block-uuid"
      assert returned_context.waiting_for_user_input == false
    end

    test "preserves other context fields while updating specific ones" do
      container = %{}
      flow = %{}
      block = %{uuid: "catalog-block-uuid"}
      context = %{
        last_block_uuid: "old-uuid",
        waiting_for_user_input: true,
        some_other_field: "preserved_value",
        another_field: 42
      }

      {:ok, _container, _flow, _block, returned_context} =
        WhatsAppCatalog.evaluate_incoming(container, flow, block, context)

      assert returned_context.last_block_uuid == "catalog-block-uuid"
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
        WhatsAppCatalog.evaluate_outgoing(container, flow, block, context, user_input)

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
        %{type: "location", lat: 40.7128, lng: -74.0060},
        nil
      ]

      for input <- test_inputs do
        {:ok, returned_input} =
          WhatsAppCatalog.evaluate_outgoing(container, flow, block, context, input)

        assert returned_input == input
      end
    end
  end
end
