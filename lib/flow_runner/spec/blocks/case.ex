defmodule FlowRunner.Spec.Blocks.Case do
  @moduledoc """
  Switch between various exit conditions.

  This is an internal block used for routing logic. Users don't call it directly
  in the DSL - it's generated from `when` conditions and `then` statements.
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

  @impl FlowRunner.Spec.Block
  @decorate with_span("FlowRunner.Case.Log.evaluate_incoming")
  def evaluate_incoming(
        %Container{} = container,
        %Flow{} = flow,
        %Block{} = block,
        %Context{} = context
      ) do
    {:ok, container, flow, block, %Context{context | last_block_uuid: block.uuid}}
  end

  @impl FlowRunner.Spec.Block
  def evaluate_outgoing(_container, _flow, block, context, nil) do
    with {:ok, block_exit} <- Block.evaluate_exits(block, context) do
      case FlowRunner.evaluate_expression_block(block_exit.name, context) do
        # We didn't manage to parse it and it returned a parsing error
        {:error, _error, _reason} -> {:ok, block_exit.name}
        # We managed to evaluate it and it returned nil
        nil -> {:ok, block_exit.name}
        value -> {:ok, value}
      end
    end
  end
end
