defmodule FlowRunner.Custom do
  @moduledoc """

  A base module from which one can implement one's custom
  flow runner.

  # Example

  ```elixir
  defmodule MyFlowRunner do
    use FlowRunner.Custom

    def fetch_flow_by_uuid(container, uuid) do
      load_from_custom_storage(uuid)
    end
  end
  ```

  """
  defmacro __using__(_opts) do
    quote do
      @behaviour FlowRunner.Contract

      defdelegate compile(json), to: FlowRunner
      defdelegate compile(blocks_module, json), to: FlowRunner
      defdelegate compile!(json), to: FlowRunner
      defdelegate compile!(blocks_module, json), to: FlowRunner

      @impl FlowRunner.Contract
      defdelegate create_context(container, flow_uuid, language, mode, vars \\ %{}),
        to: FlowRunner

      @impl FlowRunner.Contract
      defdelegate evaluate_expression(expression, context), to: FlowRunner

      @impl FlowRunner.Contract
      defdelegate evaluate_expression_block(expression, context), to: FlowRunner

      @impl FlowRunner.Contract
      defdelegate evaluate_next_block(container, flow, next_block, context), to: FlowRunner

      @impl FlowRunner.Contract
      defdelegate next_block(container, context, user_input \\ nil), to: FlowRunner

      @impl FlowRunner.Contract
      defdelegate fetch_flow_by_uuid(container, uuid), to: FlowRunner

      defoverridable(fetch_flow_by_uuid: 2)
    end
  end
end
