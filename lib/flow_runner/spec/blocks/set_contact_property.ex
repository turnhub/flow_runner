defmodule FlowRunner.Spec.Blocks.SetContactProperty do
  @moduledoc """
  Set a contact property.
  """
  @behaviour FlowRunner.Spec.Block
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
  def evaluate_incoming(
        %Container{},
        %Flow{},
        %Block{} = block,
        %Context{} = context
      ) do
    # This is a no-op as we check these fields for all blocks in FlowRunner module.
    {:ok, %Context{context | last_block_uuid: block.uuid}, %FlowRunner.Output{block: block}}
  end

  @impl true
  def evaluate_outgoing(_flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
