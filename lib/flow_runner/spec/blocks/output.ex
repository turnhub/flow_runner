defmodule FlowRunner.Spec.Blocks.Output do
  @moduledoc """
  Log things!
  """
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  require Logger

  def evaluate_incoming(
        %Flow{},
        %Block{} = block,
        %Context{} = context,
        %Container{}
      ) do
    # When Flow Results are implemented we should store the output results.
    {:ok, %Context{context | last_block_uuid: block.uuid}, nil}
  end
end
