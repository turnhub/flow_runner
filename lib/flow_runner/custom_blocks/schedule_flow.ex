defmodule FlowRunner.CustomBlocks.ScheduleFlow do
  @moduledoc """
  A custom FLOIP block for scheduling the execution of a flow
  for some time in the future (instead of executing it immediately),
  or cancelling a previously scheduled flow.
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  use FlowRunner.BlockAutodoc

  @block_category "control"
  @block_doc type: "Io.Turn.ScheduleFlow",
             dsl_name: "schedule_stack()",
             description:
               "Schedules a journey to run at a future time, or cancels a previously scheduled journey.",
             config: %{
               "flow_id" => %{
                 type: "uuid",
                 required: true,
                 description: "UUID of the flow to schedule"
               },
               "schedule_at" => %{
                 type: "datetime",
                 required: false,
                 description: "Specific datetime to run the flow"
               },
               "schedule_in" => %{
                 type: "integer",
                 required: false,
                 description: "Number of seconds in the future to run the flow"
               }
             },
             example: """
             card Card do
               # Schedule to run in 1 hour
               schedule_stack("10dca9d0-3f0b-11ed-b878-0242ac120002", in: 3600)

               # Or schedule at a specific time
               schedule_stack("some-uuid", at: datetime_add(now(), 2, "D"))
             end
             """,
             notes:
               "Either schedule_at or schedule_in must be provided. To cancel, only provide flow_id."

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
  @decorate with_span("DSL.Blocks.ScheduleFlow.evaluate_incoming")
  def evaluate_incoming(container, flow, block, context) do
    {:ok, container, flow, block,
     %{context | waiting_for_user_input: false, last_block_uuid: block.uuid}}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
