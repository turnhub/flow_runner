defmodule FlowRunner.CustomBlocks.WhatsAppCallToAction do
  @moduledoc """
  A block to handle WhatsApp interactive Call-to-Action (CTA) URL messages.

  CTA URL messages display a tappable button that opens a URL in the
  user's browser. They are useful when you want to direct users to a
  website without exposing the raw URL in the message body.

  See https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-cta-url-messages

  The `whatsapp_cta` block compiles to this FLOIP block.
  The `url`, `cta`, and `text` config parameters are required.

  The `header` and `footer` are optional.
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
                 type: "string",
                 required: false,
                 description: "Optional header text"
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

  @impl true
  def validate_config!(%{
        "cta_url" =>
          %{
            "url" => url,
            "cta" => cta,
            "text" => text
          } = params
      }) do
    optional_params = read_optional_params(params, [:header, :footer])

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

  @doc """
  For the parameter map given, read the optional keys and return a map
  for those values.

  The keys of the map are the keys supplied to this function but converted
  to strings.

  The key only exists on the returned map if a value for the key exists.
  """
  @spec read_optional_params(map, [:header | :footer]) :: %{optional(String.t()) => term}
  def read_optional_params(params, keys) do
    Enum.reduce(keys, %{}, fn key, acc ->
      param_key = to_string(key)

      if value = params[param_key], do: Map.put(acc, key, value), else: acc
    end)
  end

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
