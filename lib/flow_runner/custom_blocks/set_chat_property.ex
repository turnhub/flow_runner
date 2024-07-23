defmodule FlowRunner.CustomBlocks.SetChatProperty do
  @moduledoc """
  A custom FLOIP block for setting properties on a chat
  that is available within the current context.

  The properties able to be set are:

    * Assigned to
  """

  @behaviour FlowRunner.Spec.Block

  use OpenTelemetryDecorator

  @impl true
  def validate_config!(%{
        "assign_to" => assign_to
      }) do
    %{assign_to: assign_to}
  end

  @impl true
  @decorate trace("DSL.Blocks.SetChatProperty.evaluate_incoming")
  def evaluate_incoming(container, flow, block, context) do
    {:ok, container, flow, block,
     %{context | waiting_for_user_input: false, last_block_uuid: block.uuid}}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
