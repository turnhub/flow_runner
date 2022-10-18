defmodule FlowRunner.Spec.Blocks.RunFlow do
  @moduledoc """
  Implements the Core.RunFlow block type. Temporarily defers execution to a
  new flow.

  Specification concerns:
  - Are the requirements to call the parent context 'parentFlowContext' important?
  - What is an exception exit? It's not defined anywhere I can tell. I think it's probably
    the exit_block_id on the flow.
  """
  @behaviour FlowRunner.Spec.Block
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  @impl true
  def list_resources_referenced(_container, _block), do: []

  @impl true
  def validate_config!(%{"flow_id" => flow_id}) do
    config = %{flow_id: flow_id}

    if Vex.valid?(config, flow_id: [presence: true, uuid: true]) do
      config
    else
      raise "invalid 'config' for Core.RunFlow block, 'flow' field is required and needs to be a UUID."
    end
  end

  def validate_config!(_) do
    raise "invalid 'config' for Core.RunFlow block, 'flow' field is required and needs to be a UUID."
  end

  @impl true
  def evaluate_incoming(
        %Container{} = container,
        %Flow{} = flow,
        %Block{} = block,
        context
      ) do
    {:ok, container, flow, block,
     %{context | waiting_for_user_input: false, last_block_uuid: block.uuid}}
  end

  @impl true
  def evaluate_outgoing(_flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
