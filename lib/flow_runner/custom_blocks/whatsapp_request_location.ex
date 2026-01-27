defmodule FlowRunner.CustomBlocks.WhatsAppRequestLocation do
  @moduledoc """
  A block to handle WhatsApp request location messages.

  WhatsApp request location messages allow businesses to request
  the user's current location. This block handles the display of
  the location request with a text message and a location button.

  The `whatsapp_request_location` block compiles to this FLOIP block.
  The `text` config parameter is required for the request message.
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  use FlowRunner.BlockAutodoc

  @block_category "whatsapp"
  @block_doc type: "Io.Turn.WhatsAppRequestLocation",
             dsl_name: "request_location()",
             description:
               "Requests the user's location via WhatsApp's native location sharing feature.",
             config: %{
               "request_location.text" => %{
                 type: "string",
                 required: true,
                 description: "The message text prompting the user to share their location"
               }
             },
             example: """
             card RequestLocation do
               location = request_location("Please share your location")
             end

             card ThankYou, when: "@input.location != nil" do
               text("Thank you for sharing your location!")
             end
             """,
             returns: "The user's shared location data"

  @impl true
  def validate_config!(%{
        "request_location" => %{
          "text" => text
        }
      }) do
    %{request_location: %{text: text}}
  end

  @impl true
  def evaluate_incoming(container, flow, block, context) do
    context = %{
      context
      | last_block_uuid: block.uuid,
        # request location messages wait for user input (location)
        waiting_for_user_input: true
    }

    {:ok, container, flow, block, context}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
