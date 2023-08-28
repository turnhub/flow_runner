defmodule FlowRunner.Spec.Blocks.Log do
  @moduledoc """
  Log things!
  """
  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow
  alias FlowRunner.Spec.Resource

  require Logger

  @impl true
  def validate_config!(%{"message" => message}) do
    %{message: message}
  end

  def validate_config!(_) do
    raise "invalid config, 'message' field required"
  end

  @impl true
  def list_resources_referenced(_container, _block), do: []

  @impl true
  @decorate trace("FlowRunner.Blocks.Log.evaluate_incoming")
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
              Logger.info(FlowRunner.evaluate_expression_as_string!(log.value, context.vars))

              %Context{context | log: [log.value | context.log], last_block_uuid: block.uuid}

            {:error, reason} ->
              # credo:disable-for-next-line
              Logger.warning("Unable to resolve resource for log, reason: #{inspect(reason)}.",
                metadata: [
                  language: context.language,
                  resource: resource.uuid,
                  flow: flow.uuid,
                  container: container.uuid
                ]
              )

              %Context{context | last_block_uuid: block.uuid}
          end

        {:error, _reason} ->
          %Context{
            context
            | log: [block.config.message | context.log],
              last_block_uuid: block.uuid
          }
      end

    {:ok, container, flow, block, context}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
