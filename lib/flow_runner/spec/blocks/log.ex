defmodule FlowRunner.Spec.Blocks.Log do
  @moduledoc """
  Log things!
  """
  @behaviour FlowRunner.Spec.Block
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

  @impl true
  def evaluate_incoming(
        %Container{} = container,
        %Flow{} = flow,
        %Block{} = block,
        context
      ) do
    context =
      case Container.fetch_resource_by_uuid(container, block.config.message) do
        {:ok, resource} ->
          case Resource.matching_resource(resource, context.language, context.mode, flow) do
            {:ok, log} ->
              %Context{context | log: [log.value | context.log], last_block_uuid: block.uuid}

            {:error, reason} ->
              Logger.error("Could not fetch log message for #{block.config["message"]} #{reason}")

              context
          end

        {:error, _reason} ->
          %Context{
            context
            | log: [block.config.message | context.log],
              last_block_uuid: block.uuid
          }
      end

    {:ok, context, %Output{block: block}}
  end

  @impl true
  def evaluate_outgoing(_flow, _block, user_input) do
    {:ok, user_input}
  end
end
