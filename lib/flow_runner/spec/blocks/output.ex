defmodule FlowRunner.Spec.Blocks.Output do
  @moduledoc """
  Output to a Flow Result which is not yet implemented.
  """
  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  require Logger

  @impl true
  def validate_config!(%{"value" => value}) do
    %{value: value}
  end

  @impl true
  def list_resources_referenced(_container, _block), do: []

  @impl true
  @decorate trace("FlowRunner.Blocks.Output.evaluate_incoming")
  def evaluate_incoming(
        %Container{} = container,
        %Flow{} = flow,
        %Block{} = block,
        %Context{} = context
      ) do
    # When Flow Results are implemented we should store the output results.
    {:ok, container, flow, block, %Context{context | last_block_uuid: block.uuid}}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
