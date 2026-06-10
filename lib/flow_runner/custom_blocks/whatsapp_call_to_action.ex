defmodule FlowRunner.CustomBlocks.WhatsAppCallToAction do
  @moduledoc """
  A block to handle WhatsApp interactive Call-to-Action (CTA) URL messages.

  CTA URL messages display a tappable button that opens a URL in the
  user's browser. They are useful when you want to direct users to a
  website without exposing the raw URL in the message body.

  See https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-cta-url-messages

  The `whatsapp_cta` block compiles to this FLOIP block.
  The `url`, `cta`, and `text` config parameters are required.

  The `header` and `footer` are optional. A `header` can be text, image,
  video or document and is represented as an object with a `type`
  (`"text"`, `"image"`, `"video"` or `"document"`) and a `value` holding
  the value for that media/text.
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  use FlowRunner.BlockAutodoc

  @block_category "whatsapp"
  @block_doc type: "Io.Turn.WhatsAppCallToAction",
             dsl_name: "whatsapp_cta()",
             description:
               "Sends a WhatsApp interactive Call-to-Action (CTA) URL message with a tappable button that opens a URL.",
             config: %{
               "cta_url.url" => %{
                 type: "string",
                 required: true,
                 description: "The URL the button opens"
               },
               "cta_url.cta" => %{
                 type: "string",
                 required: true,
                 description: "Call-to-action button text"
               },
               "cta_url.text" => %{
                 type: "string",
                 required: true,
                 description: "Message body text"
               },
               "cta_url.header" => %{
                 type: "object",
                 required: false,
                 description:
                   "Optional header object with a `type` (\"text\", \"image\", \"video\" or \"document\") and a `value`"
               },
               "cta_url.footer" => %{
                 type: "string",
                 required: false,
                 description: "Optional footer text"
               }
             },
             example: """
             card Card do
               whatsapp_cta("Visit our site", "https://example.com") do
                 text("Tap the button below to learn more")
               end
             end
             """,
             returns: "Nothing; CTA URL messages do not wait for user input"

  @valid_header_types ~w(text image video document)

  @impl true
  def validate_config!(%{
        "cta_url" =>
          %{
            "url" => url,
            "cta" => cta,
            "text" => text
          } = params
      }) do
    optional_params = read_header(params)

    optional_params =
      if params["footer"],
        do: Map.put(optional_params, :footer, params["footer"]),
        else: optional_params

    cta_url_config =
      Map.merge(
        %{
          url: url,
          cta: cta,
          text: text
        },
        optional_params
      )

    %{cta_url: cta_url_config}
  end

  # A header is optional. When present it must be an object with a `type`
  # of "text", "image", "video" or "document" and a `value` holding the
  # value for that media/text.
  defp read_header(%{"header" => %{"type" => type, "value" => value}})
       when type in @valid_header_types do
    %{header: %{type: type, value: value}}
  end

  defp read_header(%{"header" => header}) do
    raise ArgumentError,
          "invalid cta_url header #{inspect(header)}: expected an object with a " <>
            "\"type\" of #{Enum.join(@valid_header_types, ", ")} and a \"value\""
  end

  defp read_header(_params), do: %{}

  @impl true
  @decorate with_span("DSL.Blocks.WhatsAppCallToAction.evaluate_incoming")
  def evaluate_incoming(container, flow, block, context) do
    context = %{context | last_block_uuid: block.uuid}

    {:ok, container, flow, block, context}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
