defmodule FlowRunner.CustomBlocks.WhatsAppTemplateMessageTest do
  use ExUnit.Case, async: true

  alias FlowRunner.CustomBlocks.WhatsAppTemplateMessage
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Exit
  alias FlowRunner.Spec.Flow

  defp block_with_components(components, exits \\ []) do
    %Block{
      uuid: "block-uuid",
      name: "ref_Template_1",
      type: "Io.Turn.WhatsAppTemplateMessage",
      config: %{template: %{components: components}},
      exits: exits
    }
  end

  defp button_component(sub_type),
    do: %{type: "button", sub_type: sub_type, index: "0", parameters: []}

  defp reply_button_component(index, payload),
    do: %{
      type: "button",
      sub_type: "quick_reply",
      index: index,
      parameters: [%{type: "payload", payload: payload, language: "eng"}]
    }

  defp context_with_template_var(value),
    do: %FlowRunner.Context{vars: %{"ref_Template_1" => value}}

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
      assert param.language == {:not_found, ["en"]}
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
      assert param.language == {:not_found, ["en"]}
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
      assert param.language == {:not_found, ["en"]}
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
      assert param.language == {:not_found, ["en"]}
    end
  end

  describe "validate_config!/1 for a flow button" do
    test "carries the flow_action_data payload through untouched" do
      config = %{
        "template" => %{
          "name" => "foo",
          "language" => %{"code" => "en"},
          "components" => [
            %{
              "type" => "button",
              "sub_type" => "flow",
              "index" => "0",
              "parameters" => [
                %{"type" => "action", "flow_action_data" => %{"patient_id" => "42"}}
              ]
            }
          ]
        }
      }

      result = WhatsAppTemplateMessage.validate_config!(config)

      assert [%{type: "button", sub_type: "flow", index: "0", parameters: [param]}] =
               result.template.components

      assert param.type == "action"
      assert param.flow_action_data == %{"patient_id" => "42"}
    end

    test "keeps an unevaluated expression payload as a string" do
      config = %{
        "template" => %{
          "name" => "foo",
          "language" => %{"code" => "en"},
          "components" => [
            %{
              "type" => "button",
              "sub_type" => "flow",
              "index" => "0",
              "parameters" => [%{"type" => "action", "flow_action_data" => "@some_var"}]
            }
          ]
        }
      }

      result = WhatsAppTemplateMessage.validate_config!(config)
      [%{parameters: [param]}] = result.template.components
      assert param.flow_action_data == "@some_var"
    end
  end

  describe "evaluate_incoming/4" do
    test "waits for user input when the template has a flow button" do
      block = block_with_components([%{type: "body"}, button_component("flow")])

      assert {:ok, _container, _flow, _block, %{waiting_for_user_input: true}} =
               WhatsAppTemplateMessage.evaluate_incoming(
                 %Container{},
                 %Flow{},
                 block,
                 %FlowRunner.Context{}
               )
    end

    test "waits for user input when the template has a quick reply button" do
      block = block_with_components([%{type: "body"}, button_component("quick_reply")])

      assert {:ok, _container, _flow, _block, %{waiting_for_user_input: true}} =
               WhatsAppTemplateMessage.evaluate_incoming(
                 %Container{},
                 %Flow{},
                 block,
                 %FlowRunner.Context{}
               )
    end

    test "does not wait when the template only has url buttons" do
      block = block_with_components([%{type: "body"}, button_component("url")])

      assert {:ok, _container, _flow, _block, %{waiting_for_user_input: false}} =
               WhatsAppTemplateMessage.evaluate_incoming(
                 %Container{},
                 %Flow{},
                 block,
                 %FlowRunner.Context{}
               )
    end

    test "does not wait when the template has no buttons" do
      block = block_with_components([%{type: "body"}])

      assert {:ok, _container, _flow, _block, %{waiting_for_user_input: false}} =
               WhatsAppTemplateMessage.evaluate_incoming(
                 %Container{},
                 %Flow{},
                 block,
                 %FlowRunner.Context{}
               )
    end
  end

  describe "evaluate_outgoing/5 for a flow submission" do
    test "returns the submitted json unwrapped so fields land on the block var" do
      block = block_with_components([%{type: "body"}, button_component("flow")])

      flow_response = %{
        "flow_token" => "a-flow-token",
        "email" => "jane@example.com",
        "slot" => "09:30"
      }

      assert {:ok, ^flow_response} =
               WhatsAppTemplateMessage.evaluate_outgoing(
                 %Container{},
                 %Flow{},
                 block,
                 %FlowRunner.Context{},
                 flow_response
               )
    end

    test "wraps a plain text reply so a non-submission still routes to the fallback exit" do
      block = block_with_components([%{type: "body"}, button_component("flow")])

      assert {:ok, %{"__value__" => "no thanks", "index" => nil}} =
               WhatsAppTemplateMessage.evaluate_outgoing(
                 %Container{},
                 %Flow{},
                 block,
                 %FlowRunner.Context{},
                 "no thanks"
               )
    end

    test "returns the submission untouched even when the block var holds a display" do
      block = block_with_components([%{type: "body"}, button_component("flow")])
      flow_response = %{"flow_token" => "a-flow-token", "email" => "jane@example.com"}

      assert {:ok, ^flow_response} =
               WhatsAppTemplateMessage.evaluate_outgoing(
                 %Container{},
                 %Flow{},
                 block,
                 context_with_template_var(%{
                   "display" => "Hello Jane!",
                   "__value__" => nil,
                   "index" => nil
                 }),
                 flow_response
               )
    end
  end

  describe "evaluate_outgoing/5 for button and text input" do
    test "returns the prefixed value when the block exits use the prefix" do
      block =
        block_with_components(
          [%{type: "body"}, button_component("quick_reply")],
          [%Exit{uuid: "exit-uuid", test: "block.value == \"template-btn-idx-0\""}]
        )

      assert {:ok, %{"__value__" => "template-btn-idx-0", "index" => "0"}} =
               WhatsAppTemplateMessage.evaluate_outgoing(
                 %Container{},
                 %Flow{},
                 block,
                 %FlowRunner.Context{},
                 "template-btn-idx-0"
               )
    end

    test "returns the bare index for legacy blocks whose exits have no prefix" do
      block =
        block_with_components(
          [%{type: "body"}, button_component("quick_reply")],
          [%Exit{uuid: "exit-uuid", test: "block.value == \"0\""}]
        )

      assert {:ok, %{"__value__" => "0", "index" => "0"}} =
               WhatsAppTemplateMessage.evaluate_outgoing(
                 %Container{},
                 %Flow{},
                 block,
                 %FlowRunner.Context{},
                 "template-btn-idx-0"
               )
    end

    test "passes nil through untouched" do
      block = block_with_components([%{type: "body"}])

      assert {:ok, nil} =
               WhatsAppTemplateMessage.evaluate_outgoing(
                 %Container{},
                 %Flow{},
                 block,
                 %FlowRunner.Context{},
                 nil
               )
    end

    test "returns only the reply keys when the block var holds nothing" do
      block =
        block_with_components(
          [%{type: "body"}, button_component("quick_reply")],
          [%Exit{uuid: "exit-uuid", test: "block.value == \"template-btn-idx-0\""}]
        )

      assert {:ok, result} =
               WhatsAppTemplateMessage.evaluate_outgoing(
                 %Container{},
                 %Flow{},
                 block,
                 %FlowRunner.Context{},
                 "template-btn-idx-0"
               )

      assert result == %{"__value__" => "template-btn-idx-0", "index" => "0", "label" => nil}
    end

    test "returns only the text keys when the block var holds nothing" do
      block = block_with_components([%{type: "body"}, button_component("quick_reply")])

      assert {:ok, result} =
               WhatsAppTemplateMessage.evaluate_outgoing(
                 %Container{},
                 %Flow{},
                 block,
                 %FlowRunner.Context{},
                 "no thanks"
               )

      assert result == %{"__value__" => "no thanks", "index" => nil}
    end
  end

  describe "evaluate_outgoing/5 brings the display set at send time" do
    test "keeps the display alongside the tapped button" do
      block =
        block_with_components(
          [%{type: "body"}, reply_button_component("0", "Yes please")],
          [%Exit{uuid: "exit-uuid", test: "block.value == \"template-btn-idx-0\""}]
        )

      assert {:ok, result} =
               WhatsAppTemplateMessage.evaluate_outgoing(
                 %Container{},
                 %Flow{},
                 block,
                 context_with_template_var(%{
                   "display" => "Hello Jane!",
                   "__value__" => nil,
                   "index" => nil
                 }),
                 "template-btn-idx-0"
               )

      assert result == %{
               "display" => "Hello Jane!",
               "__value__" => "template-btn-idx-0",
               "index" => "0",
               "label" => "Yes please"
             }
    end

    test "keeps the display alongside a free text reply" do
      block = block_with_components([%{type: "body"}, reply_button_component("0", "Yes please")])

      assert {:ok, result} =
               WhatsAppTemplateMessage.evaluate_outgoing(
                 %Container{},
                 %Flow{},
                 block,
                 context_with_template_var(%{
                   "display" => "Hello Jane!",
                   "__value__" => nil,
                   "index" => nil
                 }),
                 "maybe later"
               )

      assert result == %{
               "display" => "Hello Jane!",
               "__value__" => "maybe later",
               "index" => nil
             }
    end

    test "takes nothing but the display from the previous var" do
      block =
        block_with_components(
          [%{type: "body"}, reply_button_component("0", "Yes please")],
          [%Exit{uuid: "exit-uuid", test: "block.value == \"template-btn-idx-0\""}]
        )

      assert {:ok, result} =
               WhatsAppTemplateMessage.evaluate_outgoing(
                 %Container{},
                 %Flow{},
                 block,
                 context_with_template_var(%{
                   "display" => "Hello Jane!",
                   "__value__" => "template-btn-idx-1",
                   "index" => "1",
                   "label" => "No thanks"
                 }),
                 "template-btn-idx-0"
               )

      assert result == %{
               "display" => "Hello Jane!",
               "__value__" => "template-btn-idx-0",
               "index" => "0",
               "label" => "Yes please"
             }
    end

    test "leaves the reply untouched when the block var is not a map" do
      block = block_with_components([%{type: "body"}, button_component("quick_reply")])

      assert {:ok, result} =
               WhatsAppTemplateMessage.evaluate_outgoing(
                 %Container{},
                 %Flow{},
                 block,
                 context_with_template_var("Hello Jane!"),
                 "maybe later"
               )

      assert result == %{"__value__" => "maybe later", "index" => nil}
    end
  end

  describe "evaluate_outgoing/5 button label" do
    test "resolves the payload of the tapped button" do
      block =
        block_with_components([
          %{type: "body"},
          reply_button_component("0", "Yes please"),
          reply_button_component("1", "No thanks")
        ])

      assert {:ok, %{"index" => "1", "label" => "No thanks"}} =
               WhatsAppTemplateMessage.evaluate_outgoing(
                 %Container{},
                 %Flow{},
                 block,
                 %FlowRunner.Context{},
                 "template-btn-idx-1"
               )
    end

    test "is nil when no button sits at the tapped index" do
      block =
        block_with_components([
          %{type: "body"},
          reply_button_component("0", "Yes please"),
          reply_button_component("1", "No thanks")
        ])

      assert {:ok, %{"index" => "2", "label" => nil}} =
               WhatsAppTemplateMessage.evaluate_outgoing(
                 %Container{},
                 %Flow{},
                 block,
                 %FlowRunner.Context{},
                 "template-btn-idx-2"
               )
    end
  end
end
