defmodule FlowRunner.Spec.Blocks.Case do
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
    {:ok, %Context{context | last_block_uuid: block.uuid}, nil}
  end
end
