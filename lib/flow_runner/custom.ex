defmodule FlowRunner.Custom do
  defmacro __using__(_opts) do
    quote do
      defdelegate fetch_flow_by_uuid(container, uuid), to: FlowRunner.Spec.Container
      defdelegate fetch_resource_by_uuid(container, uuid), to: FlowRunner.Spec.Container
      defoverridable(fetch_flow_by_uuid: 2, fetch_resource_by_uuid: 2)
    end
  end
end
