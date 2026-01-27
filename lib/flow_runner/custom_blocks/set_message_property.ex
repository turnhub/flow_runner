defmodule FlowRunner.CustomBlocks.SetMessageProperty do
  @moduledoc """
  A custom FLOIP block for setting properties on a message
  that is available within the current context
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  use FlowRunner.BlockAutodoc

  @block_category "messaging"
  @block_doc type: "Io.Turn.SetMessageProperty",
             dsl_name: "add_label()",
             description: "Adds a label to a message in the current context.",
             config: %{
               "message" => %{
                 type: "string",
                 required: true,
                 description: "The message reference to label"
               },
               "labels" => %{
                 type: "list",
                 required: true,
                 description: "List of labels to apply"
               }
             },
             example: """
             card Card do
               add_label("important")
               add_label(operator)
             end
             """

  @impl true
  def validate_config!(%{
        "message" => message,
        "labels" => labels
      }) do
    %{
      message: message,
      labels: labels
    }
  end

  @impl true
  @decorate with_span("DSL.Blocks.SetMessageProperty.evaluate_incoming")
  def evaluate_incoming(container, flow, block, context) do
    {:ok, container, flow, block,
     %{context | waiting_for_user_input: false, last_block_uuid: block.uuid}}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
