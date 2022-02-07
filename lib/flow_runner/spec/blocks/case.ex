defmodule FlowRunner.Spec.Blocks.Case do
  @moduledoc """
  Switch between various exit conditions.
  """
  @behaviour FlowRunner.Spec.Block
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow
  alias FlowRunner.Output

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
    {:ok, %Context{context | last_block_uuid: block.uuid}, %Output{block: block}}
  end

  @impl true
  def evaluate_outgoing(_flow, block, context, nil) do
    {:ok, block_exit} = Block.evaluate_exits(block, context)

    FlowRunner.evaluate_expression(block_exit.name, context.vars)
  end
end
