defmodule FlowRunner.CustomBlocks.WhatsAppVoiceCallRequest do
  @moduledoc """
  A block to handle WhatsApp voice call messages.

  WhatsApp voice call messages send the user an interactive message with a
  "Call Now" button that lets them start a WhatsApp call to the business. This
  block handles the display of the request with a text message and a call button.

  The `voice_call_request` block compiles to this FLOIP block. The `text` config
  parameter is required for the body message; `display_text` is an optional
  label for the call button (the channel falls back to "Call Now" when omitted).

  Unlike `request_location` or `call_permission_request`, a voice call message
  is fire-and-forget: there is no structured reply to wait for, so execution
  continues immediately to the next block.
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  use FlowRunner.BlockAutodoc

  @block_category "whatsapp"
  @block_doc type: "Io.Turn.WhatsAppVoiceCallRequest",
             dsl_name: "voice_call_request()",
             description:
               "Sends a WhatsApp voice call message with a call button the user can tap to call the business.",
             config: %{
               "voice_call_request.text" => %{
                 type: "string",
                 required: true,
                 description: "The message body prompting the user to call"
               },
               "voice_call_request.display_text" => %{
                 type: "string",
                 required: false,
                 description: "Optional label for the call button (defaults to \"Call Now\")"
               }
             },
             example: """
             card OfferCall do
               voice_call_request("Tap below to call us", display_text: "Call support")
             end

             card NextStep do
               text("We look forward to your call!")
             end
             """,
             returns: "nil"

  @impl true
  def validate_config!(%{"voice_call_request" => %{"text" => text} = voice_call_request}) do
    %{
      voice_call_request: %{text: text, display_text: Map.get(voice_call_request, "display_text")}
    }
  end

  @impl true
  def evaluate_incoming(container, flow, block, context) do
    context = %{
      context
      | last_block_uuid: block.uuid,
        # voice call messages are fire-and-forget; there is no reply to wait for
        waiting_for_user_input: false
    }

    {:ok, container, flow, block, context}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
