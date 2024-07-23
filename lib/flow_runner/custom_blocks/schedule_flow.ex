defmodule FlowRunner.CustomBlocks.ScheduleFlow do
  @moduledoc """
  A custom FLOIP block for scheduling the execution of a flow
  for some time in the future (instead of executing it immediately),
  or cancelling a previously scheduled flow.
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator

  @impl true
  @spec validate_config!(map) :: %{
          :flow_id => String.t(),
          optional(:schedule_at) => DateTime.t(),
          optional(:schedule_in) => integer
        }
  def validate_config!(%{
        "flow_id" => flow_id,
        "schedule_in" => schedule_in
      }) do
    %{
      flow_id: flow_id,
      schedule_in: schedule_in
    }
  end

  def validate_config!(%{
        "flow_id" => flow_id,
        "schedule_at" => schedule_at
      }) do
    %{
      flow_id: flow_id,
      schedule_at: schedule_at
    }
  end

  # this is for cancellation of a scheduled flow
  def validate_config!(%{"flow_id" => flow_id}), do: %{flow_id: flow_id}

  @impl true
  @decorate trace("DSL.Blocks.ScheduleFlow.evaluate_incoming")
  def evaluate_incoming(container, flow, block, context) do
    {:ok, container, flow, block,
     %{context | waiting_for_user_input: false, last_block_uuid: block.uuid}}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
