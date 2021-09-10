defmodule FlowRunner.Spec.Blocks.Message do
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Resource

    alias FlowRunner.Context
    alias FlowRunner.Spec.Container
    alias FlowRunner.Spec.Resource

    def evaluate_incoming(flow, block, context, container) do
        resource = Container.fetch_resource_by_uuid(container, block.config["prompt"])
        prompt = Resource.matching_resource(resource, context.language, context.mode, flow)
        output = %FlowRunner.Output{
            prompt: prompt,
        }
        context = %Context{context | waiting_for_user_input: false}
        {:ok, context, output}
    end
end
