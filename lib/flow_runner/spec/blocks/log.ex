defmodule FlowRunner.Spec.Blocks.Log do
  @moduledoc """
  Log things!
  """
  alias FlowRunner.Context
  alias FlowRunner.Output
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow
  alias FlowRunner.Spec.Resource

  require Logger

  def validate_config!(%{"message" => message}) do
    %{message: message}
  end

  def validate_config!(_) do
    raise "invalid config, 'message' field required"
  end

  def evaluate_incoming(
        %Flow{} = flow,
        %Block{} = block,
        context,
        %Container{} = container
      ) do
    {:ok, resource} = Container.fetch_resource_by_uuid(container, block.config.message)

    context =
      case Resource.matching_resource(resource, context.language, context.mode, flow) do
        {:ok, log} ->
          %Context{context | log: [log.value | context.log], last_block_uuid: block.uuid}

        {:error, reason} ->
          Logger.error("Could not fetch log message for #{block.config["message"]} #{reason}")
          context
      end

    {:ok, context, %Output{}}
  end

  def evaluate_outgoing(_block, user_input) do
    {:ok, user_input}
  end
end
