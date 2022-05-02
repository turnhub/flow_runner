defmodule FlowRunner.Spec.Blocks.Output do
  @moduledoc """
  Output to a Flow Result which is not yet implemented.
  """
  @behaviour FlowRunner.Spec.Block
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
  def evaluate_incoming(
        %Container{},
        %Flow{},
        %Block{} = block,
        %Context{} = context
      ) do
    # When Flow Results are implemented we should store the output results.
    {:ok, %Context{context | last_block_uuid: block.uuid}, %FlowRunner.Output{block: block}}
  end

  @impl true
  def evaluate_outgoing(_flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
