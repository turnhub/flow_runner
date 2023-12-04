defmodule FlowRunner.Spec.Blocks.SetContactProperty do
  @moduledoc """
  Set a contact property.
  """
  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  require Logger

  @impl true
  def validate_config!(_) do
    %{}
  end

  @impl true
  @decorate trace("FlowRunner.Blocks.SetContactProperty.evaluate_incoming")
  def evaluate_incoming(
        %Container{} = container,
        %Flow{} = flow,
        %Block{} = block,
        %Context{} = context
      ) do
    # This is a no-op as we check these fields for all blocks in FlowRunner module.
    {:ok, container, flow, block, %Context{context | last_block_uuid: block.uuid}}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
