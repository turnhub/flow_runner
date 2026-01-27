defmodule FlowRunner.CustomBlocks.SetChatProperty do
  @moduledoc """
  A custom FLOIP block for setting properties on a chat
  that is available within the current context.

  The properties able to be set are:

    * Assigned to
  """

  @behaviour FlowRunner.Spec.Block

  use OpenTelemetryDecorator
  use FlowRunner.BlockAutodoc

  @block_category "chat"
  @block_doc type: "Io.Turn.SetChatProperty",
             dsl_name: "assign_chat_to()",
             description: "Assigns the current chat to a user or queue.",
             config: %{
               "assign_to" => %{
                 type: "string",
                 required: true,
                 description: "Email of the user to assign the chat to"
               }
             },
             example: """
             card Card do
               assign_chat_to("support@example.com")
             end
             """

  @impl true
  def validate_config!(%{
        "assign_to" => assign_to
      }) do
    %{assign_to: assign_to}
  end

  @impl true
  @decorate with_span("DSL.Blocks.SetChatProperty.evaluate_incoming")
  def evaluate_incoming(container, flow, block, context) do
    {:ok, container, flow, block,
     %{context | waiting_for_user_input: false, last_block_uuid: block.uuid}}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
