defmodule FlowRunner.CustomBlocks.WhatsAppTemplateMessage do
  @moduledoc """
  A block to handle the sending of the WhatsApp message templates
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  use FlowRunner.BlockAutodoc

  @block_category "whatsapp"
  @block_doc type: "Io.Turn.WhatsAppTemplateMessage",
             dsl_name: "send_message_template()",
             description: "Sends a WhatsApp message template with dynamic parameters.",
             config: %{
               "template.name" => %{
                 type: "string",
                 required: true,
                 description: "The name of the template"
               },
               "template.language.code" => %{
                 type: "string",
                 required: true,
                 description: "Language code for the template"
               },
               "template.components" => %{
                 type: "list",
                 required: true,
                 description: "List of template components with parameters"
               }
             },
             example: """
             card Card do
               send_message_template("template_name", "en", ["param-1", "param-2"])
             end
             """,
             returns:
               "The submitted JSON when the template has a flow button, otherwise a map " <>
                 "with __value__ and index when the template has reply buttons"
  @impl FlowRunner.Spec.Block
  def validate_config!(%{
        "template" =>
          %{
            "name" => name,
            "language" => %{"code" => code},
            "components" => components
          } = template
      }) do
    %{
      template: %{
        name: name,
        language: %{code: code},
        components: Enum.map(components, &parse_component(&1, code)),
        tracking: Map.get(template, "tracking")
      }
    }
  end

  @spec parse_component(
          %{
            required(String.t()) => String.t(),
            required(String.t()) => list(%{String.t() => String.t()})
          },
          String.t()
        ) :: %{
          type: String.t(),
          index: String.t() | nil,
          sub_type: String.t() | nil,
          parameters:
            list(%{
              required(:type) => String.t(),
              optional(:text) => String.t(),
              optional(:payload) => String.t(),
              optional(:flow_action_data) => term(),
              optional(:language) => String.t()
            })
        }
  defp parse_component(
         %{"type" => type, "parameters" => parameters} = component,
         default_language
       ),
       do: %{
         type: type,
         index: component["index"],
         # required only for buttons
         sub_type: component["sub_type"],
         parameters: Enum.map(parameters, &parse_parameter(&1, default_language))
       }

  defp parse_parameter(%{"type" => "text", "text" => text} = component, default_language),
    do: %{
      type: "text",
      text: text,
      language: component["language"] || Expression.evaluate_block!(default_language)
    }

  defp parse_parameter(
         %{"type" => "document", "document" => %{"link" => link} = document},
         default_language
       ) do
    document =
      if filename = document["filename"] do
        %{link: link, filename: filename}
      else
        %{link: link}
      end

    %{
      type: "document",
      document: document,
      language: document["language"] || Expression.evaluate_block!(default_language)
    }
  end

  defp parse_parameter(
         %{"type" => "video", "video" => %{"link" => link}} = video,
         default_language
       ),
       do: %{
         type: "video",
         video: %{link: link},
         language: video["language"] || Expression.evaluate_block!(default_language)
       }

  defp parse_parameter(
         %{"type" => "image", "image" => %{"link" => link}} = image,
         default_language
       ),
       do: %{
         type: "image",
         image: %{link: link},
         language: image["language"] || Expression.evaluate_block!(default_language)
       }

  defp parse_parameter(
         %{"type" => "payload", "payload" => payload_resource_uuid} = payload,
         default_language
       ),
       do: %{
         type: "payload",
         payload: payload_resource_uuid,
         language: payload["language"] || Expression.evaluate_block!(default_language)
       }

  # The parameter of a flow button. `flow_action_data` is the data payload for the
  # flow's first screen and is carried through untouched: it may be a decoded JSON
  # object, or a string holding an expression to evaluate when the template is sent.
  defp parse_parameter(%{"type" => "action"} = action, default_language),
    do: %{
      type: "action",
      flow_action_data: action["flow_action_data"],
      language: action["language"] || Expression.evaluate_block!(default_language)
    }

  @impl FlowRunner.Spec.Block
  @decorate with_span("DSL.Blocks.WhatsAppTemplateMessage.evaluate_incoming")
  def evaluate_incoming(container, flow, block, context) do
    context = %{
      context
      | last_block_uuid: block.uuid,
        # if the template has a reply button, we need to wait for user input
        waiting_for_user_input: has_reply_button?(block.config.template.components)
    }

    {:ok, container, flow, block, context}
  end

  @impl FlowRunner.Spec.Block
  def evaluate_outgoing(_container, _flow, _block, _context, nil), do: {:ok, nil}

  # A WhatsApp Flow submission arrives as a decoded JSON reply, which always
  # carries the `flow_token` echoed from the outbound message. Return it unwrapped so
  # the submitted fields land directly on the block's var (`@ref_Template_1.email`),
  # matching how `Io.Turn.WhatsAppSendFlow` exposes its result.
  def evaluate_outgoing(_container, _flow, _block, _context, %{"flow_token" => _} = flow_response) do
    {:ok, flow_response}
  end

  @template_button_indices Enum.map(0..9, &to_string/1)
  def evaluate_outgoing(_container, _flow, block, _context, "template-btn-idx-" <> index)
      when index in @template_button_indices do
    value =
      if has_reply_button?(block.config.template.components) do
        # This is needed to keep backward compatibility with
        # old blocks whose exits don't have the prefix "template-btn-idx-".
        is_button_prefixed? =
          Enum.any?(block.exits, &String.contains?(&1.test, "template-btn-idx-"))

        if is_button_prefixed?, do: "template-btn-idx-" <> index, else: index
      else
        index
      end

    {:ok, %{"__value__" => value, "index" => index}}
  end

  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, %{"__value__" => user_input, "index" => nil}}
  end

  defp has_reply_button?(components),
    do: Enum.any?(components, &(&1[:type] == "button" and &1[:sub_type] != "url"))
end
