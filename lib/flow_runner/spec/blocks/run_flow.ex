defmodule FlowRunner.Spec.Blocks.RunFlow do
  @moduledoc """
  Implements the Core.RunFlow block type. Temporarily defers execution to a
  new flow.

  Specification concerns:
  - Are the requirements to call the parent context 'parentFlowContext' important?
  - What is an exception exit? It's not defined anywhere I can tell. I think it's probably
    the exit_block_id on the flow.
  """
  alias FlowRunner.Context
  alias FlowRunner.Output
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  def evaluate_incoming(%Flow{}, %Block{config: config} = block, context, %Container{}) do
    next_flow_id = config["flow_id"]

    context = %Context{context | last_block_uuid: block.uuid}

    next_context = %Context{
      Context.clone_empty(context)
      | parent_context: context,
        current_flow_uuid: next_flow_id,
        last_block_uuid: nil
    }

    {:ok, next_context, %Output{}}
  end

  def evaluate_outgoing(_block, context, _flow, _user_input) do
    {:ok, context}
  end
end
