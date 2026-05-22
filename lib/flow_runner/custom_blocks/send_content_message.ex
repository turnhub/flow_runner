defmodule FlowRunner.CustomBlocks.SendContentMessage do
  @moduledoc """
  A block to handle the sending of content cards from Turn
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  use FlowRunner.BlockAutodoc

  @block_category "messaging"
  @block_doc type: "Io.Turn.SendContentMessage",
             dsl_name: "send_content()",
             description:
               "Sends a content card (pre-defined message template) from Turn's content library.",
             config: %{
               "content.uuid" => %{
                 type: "uuid",
                 required: true,
                 description: "UUID of the content card to send"
               },
               "content.wait_for_input" => %{
                 type: "boolean | expression",
                 required: true,
                 description: "Whether to wait for user input after sending"
               }
             },
             example: """
             card Card do
               send_content("content-uuid-here")
               # Or wait for response:
               resp = send_content("content-uuid-here", true)
             end
             """
  @impl true
  def validate_config!(%{
        "content" =>
          %{
            "uuid" => uuid,
            "wait_for_input" => wait_for_input
          } = _template
      }) do
    %{
      content: %{
        uuid: uuid,
        wait_for_input: wait_for_input
      }
    }
  end

  @impl true
  @decorate with_span("DSL.Blocks.SendContentMessage.evaluate_incoming")
  def evaluate_incoming(container, flow, block, context) do
    # if the config's wait_for_input resolves to true, we need to wait for user input

    # Fetch the resource
    {:ok, resource} =
      FlowRunner.fetch_resource_by_uuid(container, block.config.content.wait_for_input)

    # Fetch the resource value
    {:ok, resource_value} =
      FlowRunner.fetch_resource_value(resource, context.language, context.mode, flow)

    # evaluate the expression to a boolean, using !! so nils evaluate to false
    waiting_for_user_input =
      case FlowRunner.evaluate_expression_block(resource_value.value, context.vars) do
        {:error, _} -> false
        result -> !!result
      end

    {:ok, container, flow, block,
     %{
       context
       | waiting_for_user_input: waiting_for_user_input,
         last_block_uuid: block.uuid
     }}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
