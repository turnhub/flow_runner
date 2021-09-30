defmodule FlowRunner.Spec.Blocks.Log do
  @moduledoc """
  Log things!
  """
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow
  alias FlowRunner.Spec.Resource

  require Logger

  def evaluate_incoming(
        %Flow{} = flow,
        %Block{} = block,
        context,
        %Container{} = container
      ) do
    {:ok, resource} = Container.fetch_resource_by_uuid(container, block.config["message"])

    context =
      case Resource.matching_resource(resource, context.language, context.mode, flow) do
        {:ok, log} ->
          %Context{context | log: [log.value | context.log], last_block_uuid: block.uuid}

        {:error, reason} ->
          Logger.error("Could not fetch log message for #{block.config["message"]} #{reason}")
          context
      end

    {:ok, context, nil}
  end
end
