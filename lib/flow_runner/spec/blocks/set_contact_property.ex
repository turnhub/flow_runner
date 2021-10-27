defmodule FlowRunner.Spec.Blocks.SetContactProperty do
  @moduledoc """
  Set a contact property.
  """
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  require Logger

  def validate_config!(_) do
    %{}
  end

  def evaluate_incoming(
        %Flow{},
        %Block{} = block,
        %Context{} = context,
        %Container{}
      ) do
    # This is a no-op as we check these fields for all blocks in FlowRunner module.
    {:ok, %Context{context | last_block_uuid: block.uuid}, %FlowRunner.Output{}}
  end

  def evaluate_outgoing(_flow, _block, user_input) do
    {:ok, user_input}
  end
end