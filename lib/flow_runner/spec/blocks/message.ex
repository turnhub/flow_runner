defmodule FlowRunner.Spec.Blocks.Message do
  @moduledoc """
  A type of block that sends a message to the user.
  """
  alias FlowRunner.Context
  alias FlowRunner.Output
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow
  alias FlowRunner.Spec.Resource

  def evaluate_incoming(%Flow{} = flow, %Block{} = block, context, container) do
    {:ok, resource} = Container.fetch_resource_by_uuid(container, block.config["prompt"])

    case Resource.matching_resource(resource, context.language, context.mode, flow) do
      {:ok, prompt} ->
        {
          :ok,
          %Context{context | waiting_for_user_input: false, last_block_uuid: block.uuid},
          %Output{
            prompt: prompt
          }
        }

      {:error, reason} ->
        {:error, reason}
    end
  end
end
