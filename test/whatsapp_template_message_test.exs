defmodule FlowRunner.CustomBlocks.WhatsAppTemplateMessageTest do
  use ExUnit.Case, async: true

  alias FlowRunner.CustomBlocks.WhatsAppTemplateMessage

  describe "validate_config!/1 for document parameter" do
    test "returns document with filename when present" do
      config = %{"template" => %{
        "name" => "foo",
        "language" => %{"code" => "en"},
        "components" => [
          %{"type" => "body", "parameters" => [
            %{"type" => "document", "document" => %{"link" => "http://file", "filename" => "file.pdf"}}
          ]}
        ]
      }}
      result = WhatsAppTemplateMessage.validate_config!(config)
      [%{parameters: [param]}] = result.template.components
      assert param.type == "document"
      assert param.document == %{link: "http://file", filename: "file.pdf"}
    end

    test "returns document without filename when not present" do
      config = %{"template" => %{
        "name" => "foo",
        "language" => %{"code" => "en"},
        "components" => [
          %{"type" => "body", "parameters" => [
            %{"type" => "document", "document" => %{"link" => "http://file"}}
          ]}
        ]
      }}
      result = WhatsAppTemplateMessage.validate_config!(config)
      [%{parameters: [param]}] = result.template.components
      assert param.type == "document"
      assert param.document == %{link: "http://file"}
    end
  end
end
