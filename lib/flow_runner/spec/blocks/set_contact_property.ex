defmodule FlowRunner.Spec.Blocks.SetContactProperty do
  @moduledoc """
  Set a contact property.
  """
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  require Logger

  def evaluate_incoming(
        %Flow{},
        %Block{} = block,
        %Context{} = context,
        %Container{}
      ) do
    # This is a no-op as we check these fields for all blocks in FlowRunner module.
    {:ok, %Context{context | last_block_uuid: block.uuid}, %FlowRunner.Output{}}
  end
end
