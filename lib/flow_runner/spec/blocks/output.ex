defmodule FlowRunner.Spec.Blocks.Output do
  @moduledoc """
  Output to a Flow Result which is not yet implemented.
  """
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  require Logger

  def validate_config!(_config) do
    %{}
  end

  def evaluate_incoming(
        %Flow{},
        %Block{} = block,
        %Context{} = context,
        %Container{}
      ) do
    # When Flow Results are implemented we should store the output results.
    {:ok, %Context{context | last_block_uuid: block.uuid}, %FlowRunner.Output{block: block}}
  end

  def evaluate_outgoing(_flow, _block, user_input) do
    {:ok, user_input}
  end
end
