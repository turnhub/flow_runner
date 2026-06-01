defmodule FlowRunner.CustomBlocks.WhatsAppCallPermissionRequest do
  @moduledoc """
  A block to handle WhatsApp call permission request messages.

  WhatsApp call permission request messages allow businesses to ask
  the user for permission to call them. This block handles the display
  of the permission request with a text message and a permission button.

  The `call_permission_request` block compiles to this FLOIP block.
  The `text` config parameter is required for the request message.
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  use FlowRunner.BlockAutodoc

  @block_category "whatsapp"
  @block_doc type: "Io.Turn.WhatsAppCallPermissionRequest",
             dsl_name: "call_permission_request()",
             description:
               "Requests permission to call the user via WhatsApp's native call permission feature.",
             config: %{
               "call_permission_request.text" => %{
                 type: "string",
                 required: true,
                 description: "The message text prompting the user to grant call permission"
               }
             },
             example: """
             card RequestPermission do
               granted = call_permission_request("Can we call you to assist?")
             end

             card ThankYou do
               text("Thank you!")
             end
             """,
             returns: "The user's call permission response"

  @impl true
  def validate_config!(%{"call_permission_request" => %{"text" => text}}) do
    %{call_permission_request: %{text: text}}
  end

  @impl true
  def evaluate_incoming(container, flow, block, context) do
    context = %{
      context
      | last_block_uuid: block.uuid,
        # call permission request messages wait for user input (permission reply)
        waiting_for_user_input: true
    }

    {:ok, container, flow, block, context}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
