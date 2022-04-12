defmodule FlowRunner.Custom do
  defmacro __using__(_opts) do
    quote do
      @behaviour FlowRunner

      defdelegate compile(json), to: FlowRunner
      defdelegate compile(blocks_module, json), to: FlowRunner
      defdelegate compile!(json), to: FlowRunner
      defdelegate compile!(blocks_module, json), to: FlowRunner

      @impl FlowRunner
      defdelegate create_context(container, flow_uuid, language, mode, vars \\ %{}),
        to: FlowRunner

      @impl FlowRunner
      defdelegate evaluate_expression(expression, context), to: FlowRunner

      @impl FlowRunner
      defdelegate evaluate_expression_block(expression, context), to: FlowRunner

      @impl FlowRunner
      defdelegate evaluate_next_block(container, flow, next_block, context), to: FlowRunner

      @impl FlowRunner
      defdelegate next_block(container, context, user_input \\ nil), to: FlowRunner

      @impl FlowRunner
      defdelegate fetch_flow_by_uuid(container, uuid), to: FlowRunner

      defoverridable(fetch_flow_by_uuid: 2)
    end
  end
end
