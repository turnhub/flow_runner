defmodule FlowRunner.Spec.Blocks.Case do
  @moduledoc """
  Switch between various exit conditions.
  """
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow
  alias FlowRunner.Output

  require Logger

  def validate_config!(_) do
    %{}
  end

  def evaluate_incoming(
        %Flow{},
        %Block{} = block,
        %Context{} = context,
        %Container{}
      ) do
    {:ok, %Context{context | last_block_uuid: block.uuid}, %Output{block: block}}
  end

  def evaluate_outgoing(_flow, _block, user_input) do
    {:ok, user_input}
  end
end
