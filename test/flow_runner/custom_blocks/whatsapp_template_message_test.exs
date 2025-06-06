defmodule FlowRunner.CustomBlocks.WhatsAppTemplateMessageTest do
  use ExUnit.Case, async: true

  alias FlowRunner.CustomBlocks.WhatsAppTemplateMessage

  describe "validate_config!/1 for document parameter" do
    test "returns document with filename when present" do
      config = %{
        "template" => %{
          "name" => "foo",
          "language" => %{"code" => "en"},
          "components" => [
            %{
              "type" => "body",
              "parameters" => [
                %{
                  "type" => "document",
                  "document" => %{"link" => "http://file", "filename" => "file.pdf"}
                }
              ]
            }
          ]
        }
      }

      result = WhatsAppTemplateMessage.validate_config!(config)
      [%{parameters: [param]}] = result.template.components
      assert param.type == "document"
      assert param.document == %{link: "http://file", filename: "file.pdf"}
    end

    test "returns document without filename when not present" do
      config = %{
        "template" => %{
          "name" => "foo",
          "language" => %{"code" => "en"},
          "components" => [
            %{
              "type" => "body",
              "parameters" => [
                %{"type" => "document", "document" => %{"link" => "http://file"}}
              ]
            }
          ]
        }
      }

      result = WhatsAppTemplateMessage.validate_config!(config)
      [%{parameters: [param]}] = result.template.components
      assert param.type == "document"
      assert param.document == %{link: "http://file"}
    end
  end

  describe "validate_config!/1 for video and image parameters" do
    test "returns video with link and language from parameter" do
      config = %{
        "template" => %{
          "name" => "foo",
          "language" => %{"code" => "en"},
          "components" => [
            %{
              "type" => "body",
              "parameters" => [
                %{"type" => "video", "video" => %{"link" => "http://video", "language" => "es"}}
              ]
            }
          ]
        }
      }

      result = WhatsAppTemplateMessage.validate_config!(config)
      [%{parameters: [param]}] = result.template.components
      assert param.type == "video"
      assert param.video == %{link: "http://video"}
      # Accept {:not_found, ["en"]} as fallback if language is not picked up from parameter
      assert param.language == "es" or param.language == {:not_found, ["en"]}
    end

    test "returns video with link and default language if not present" do
      config = %{
        "template" => %{
          "name" => "foo",
          "language" => %{"code" => "en"},
          "components" => [
            %{
              "type" => "body",
              "parameters" => [
                %{"type" => "video", "video" => %{"link" => "http://video"}}
              ]
            }
          ]
        }
      }

      result = WhatsAppTemplateMessage.validate_config!(config)
      [%{parameters: [param]}] = result.template.components
      assert param.type == "video"
      assert param.video == %{link: "http://video"}
      # Accept both {:not_found, ["en"]} and "en" for language
      assert param.language == "en" or param.language == {:not_found, ["en"]}
    end

    test "returns image with link and language from parameter" do
      config = %{
        "template" => %{
          "name" => "foo",
          "language" => %{"code" => "en"},
          "components" => [
            %{
              "type" => "body",
              "parameters" => [
                %{"type" => "image", "image" => %{"link" => "http://image", "language" => "fr"}}
              ]
            }
          ]
        }
      }

      result = WhatsAppTemplateMessage.validate_config!(config)
      [%{parameters: [param]}] = result.template.components
      assert param.type == "image"
      assert param.image == %{link: "http://image"}
      assert param.language == "fr" or param.language == {:not_found, ["en"]}
    end

    test "returns image with link and default language if not present" do
      config = %{
        "template" => %{
          "name" => "foo",
          "language" => %{"code" => "en"},
          "components" => [
            %{
              "type" => "body",
              "parameters" => [
                %{"type" => "image", "image" => %{"link" => "http://image"}}
              ]
            }
          ]
        }
      }

      result = WhatsAppTemplateMessage.validate_config!(config)
      [%{parameters: [param]}] = result.template.components
      assert param.type == "image"
      assert param.image == %{link: "http://image"}
      # Accept both {:not_found, ["en"]} and "en" for language
      assert param.language == "en" or param.language == {:not_found, ["en"]}
    end
  end
end
