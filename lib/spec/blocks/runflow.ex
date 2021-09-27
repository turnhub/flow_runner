defmodule FlowRunner.Spec.Blocks.RunFlow do
  @moduledoc """
  Implements the Core.RunFlow block type. Temporarily defers execution to a
  new flow.

  TODO:
  - Trap

  Specification concerns:
  - Are the requirements to call the parent context 'parentFlowContext' important?
  - What is an exception exit? It's not defined anywhere I can tell. I think it's probably
    the exit_block_id on the flow.
  """
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  def evaluate_incoming(%Flow{}, %Block{config: config}, context, %Container{}) do
    next_flow_id = config["flow_id"]

    next_context = %Context{
      Context.clone_empty(context)
      | parent_context: context,
        current_flow_uuid: next_flow_id
    }

    {:ok, next_context, nil}
  end
end