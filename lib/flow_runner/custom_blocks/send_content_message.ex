defmodule FlowRunner.CustomBlocks.SendContentMessage do
  @moduledoc """
  A block to handle the sending of content cards from Turn
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
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
      !!FlowRunner.evaluate_expression_block(resource_value.value, context.vars)

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
