defmodule FlowRunner.CustomBlocks.WhatsAppTemplateMessage do
  @moduledoc """
  A block to handle the sending of the WhatsApp message templates
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  @impl true
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
        components: Enum.map(components, &parse_component/1),
        tracking: Map.get(template, "tracking")
      }
    }
  end

  def parse_component(%{"type" => type, "parameters" => parameters} = component),
    do: %{
      type: type,
      index: component["index"],
      # required only for buttons
      sub_type: component["sub_type"],
      parameters: Enum.map(parameters, &parse_parameter/1)
    }

  def parse_parameter(%{"type" => "text", "text" => text}),
    do: %{type: "text", text: text}

  def parse_parameter(%{"type" => "document", "document" => %{"link" => link} = document}) do
    document =
      if filename = document["filename"] do
        %{link: link, filename: filename}
      else
        %{link: link}
      end

    %{type: "document", document: document}
  end

  def parse_parameter(%{"type" => "video", "video" => %{"link" => link}}),
    do: %{type: "video", video: %{link: link}}

  def parse_parameter(%{"type" => "image", "image" => %{"link" => link}}),
    do: %{type: "image", image: %{link: link}}

  def parse_parameter(%{"type" => "payload", "payload" => payload_resource_uuid}),
    do: %{type: "payload", payload: payload_resource_uuid}

  @impl true
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

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, nil), do: {:ok, nil}

  def evaluate_outgoing(_container, _flow, block, _context, user_input) do
    index = if has_reply_button?(block.config.template.components), do: user_input, else: nil

    {:ok, %{"__value__" => user_input, "index" => index}}
  end

  defp has_reply_button?(components),
    do: Enum.any?(components, &(&1[:type] == "button" and &1[:sub_type] != "url"))
end
