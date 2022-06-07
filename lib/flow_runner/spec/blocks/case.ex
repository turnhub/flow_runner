defmodule FlowRunner.Spec.Blocks.Case do
  @moduledoc """
  Switch between various exit conditions.
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
        %Container{} = container,
        %Flow{} = flow,
        %Block{} = block,
        %Context{} = context
      ) do
    {:ok, container, flow, block, %Context{context | last_block_uuid: block.uuid}}
  end

  @impl true
  def evaluate_outgoing(_flow, block, context, nil) do
    {:ok, block_exit} = Block.evaluate_exits(block, context)

    case FlowRunner.evaluate_expression_block(block_exit.name, context.vars) do
      {:ok, [result]} ->
        {:ok, result}

      {:error, _reason} ->
        {:ok, block_exit.name}
    end
  end
end
