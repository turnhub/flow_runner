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
  use OpenTelemetryDecorator
  use FlowRunner.BlockAutodoc

  @block_category "control"
  @block_doc type: "Core.RunFlow",
             dsl_name: "run_stack()",
             description:
               "Runs another journey (stack) and returns to the current flow when complete.",
             config: %{
               "flow_id" => %{
                 type: "uuid",
                 required: true,
                 description: "UUID of the flow to run"
               }
             },
             example: """
             card Card do
               run_stack("10dca9d0-3f0b-11ed-b878-0242ac120002")
             end
             """
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

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
  @decorate with_span("FlowRunner.Blocks.RunFlow.evaluate_incoming")
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
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
