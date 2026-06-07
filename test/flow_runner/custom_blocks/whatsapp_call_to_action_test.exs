defmodule FlowRunner.CustomBlocks.WhatsAppCallToActionTest do
  use ExUnit.Case, async: true

  alias FlowRunner.CustomBlocks.WhatsAppCallToAction

  describe "validate_config!/1" do
    test "returns cta_url config with required url, cta and text parameters" do
      config = %{
        "cta_url" => %{
          "url" => "https://example.com",
          "cta" => "Visit our site",
          "text" => "Tap the button below to learn more"
        }
      }

      result = WhatsAppCallToAction.validate_config!(config)

      assert result.cta_url.url == "https://example.com"
      assert result.cta_url.cta == "Visit our site"
      assert result.cta_url.text == "Tap the button below to learn more"
      refute Map.has_key?(result.cta_url, :header)
      refute Map.has_key?(result.cta_url, :footer)
    end

    test "returns cta_url config with optional header and footer parameters" do
      config = %{
        "cta_url" => %{
          "url" => "https://example.com",
          "cta" => "Visit our site",
          "text" => "Tap the button below to learn more",
          "header" => "Header text",
          "footer" => "Footer text"
        }
      }

      result = WhatsAppCallToAction.validate_config!(config)

      assert result.cta_url.header == "Header text"
      assert result.cta_url.footer == "Footer text"
    end

    test "raises error when cta_url key is missing" do
      config = %{}

      assert_raise FunctionClauseError, fn ->
        WhatsAppCallToAction.validate_config!(config)
      end
    end

    test "raises error when url parameter is missing" do
      config = %{
        "cta_url" => %{
          "cta" => "Visit our site",
          "text" => "Tap the button below to learn more"
        }
      }

      assert_raise FunctionClauseError, fn ->
        WhatsAppCallToAction.validate_config!(config)
      end
    end

    test "raises error when cta parameter is missing" do
      config = %{
        "cta_url" => %{
          "url" => "https://example.com",
          "text" => "Tap the button below to learn more"
        }
      }

      assert_raise FunctionClauseError, fn ->
        WhatsAppCallToAction.validate_config!(config)
      end
    end

    test "raises error when text parameter is missing" do
      config = %{
        "cta_url" => %{
          "url" => "https://example.com",
          "cta" => "Visit our site"
        }
      }

      assert_raise FunctionClauseError, fn ->
        WhatsAppCallToAction.validate_config!(config)
      end
    end
  end

  describe "read_optional_params/2" do
    test "returns empty map when no optional parameters are present" do
      params = %{"url" => "https://example.com"}
      keys = [:header, :footer]

      result = WhatsAppCallToAction.read_optional_params(params, keys)

      assert result == %{}
    end

    test "returns map with only present optional parameters" do
      params = %{
        "url" => "https://example.com",
        "footer" => "footer text"
      }

      keys = [:header, :footer]

      result = WhatsAppCallToAction.read_optional_params(params, keys)

      assert result == %{footer: "footer text"}
    end

    test "returns map with all optional parameters when present" do
      params = %{
        "header" => "header text",
        "footer" => "footer text"
      }

      keys = [:header, :footer]

      result = WhatsAppCallToAction.read_optional_params(params, keys)

      assert result == %{header: "header text", footer: "footer text"}
    end
  end

  describe "evaluate_incoming/4" do
    test "updates last_block_uuid without waiting for user input" do
      container = %{}
      flow = %{}
      block = %{uuid: "test-block-uuid"}

      context = %{
        last_block_uuid: "previous-uuid",
        waiting_for_user_input: false
      }

      {:ok, returned_container, returned_flow, returned_block, returned_context} =
        WhatsAppCallToAction.evaluate_incoming(container, flow, block, context)

      assert returned_container == container
      assert returned_flow == flow
      assert returned_block == block
      assert returned_context.last_block_uuid == "test-block-uuid"
      assert returned_context.waiting_for_user_input == false
    end

    test "preserves other context fields while updating last_block_uuid" do
      container = %{}
      flow = %{}
      block = %{uuid: "cta-block-uuid"}

      context = %{
        last_block_uuid: "old-uuid",
        waiting_for_user_input: false,
        some_other_field: "preserved_value",
        another_field: 42
      }

      {:ok, _container, _flow, _block, returned_context} =
        WhatsAppCallToAction.evaluate_incoming(container, flow, block, context)

      assert returned_context.last_block_uuid == "cta-block-uuid"
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
        WhatsAppCallToAction.evaluate_outgoing(container, flow, block, context, user_input)

      assert returned_input == user_input
    end
  end
end
