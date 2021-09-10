defmodule FlowRunner.Spec.Blocks.SelectOneResponse do
  @moduledoc """
  A specialisation of a block that sends users a set of options and
  waits for the user to come back with one of them.
  """
  alias FlowRunner.Context
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Resource

  def evaluate_incoming(flow, block, context, container) do
    resource = Container.fetch_resource_by_uuid(container, block.config["prompt"])
    prompt = Resource.matching_resource(resource, context.language, context.mode, flow)

    output = %FlowRunner.Output{
      prompt: prompt
    }

    context = %Context{context | waiting_for_user_input: true}
    {:ok, context, output}
  end
end
