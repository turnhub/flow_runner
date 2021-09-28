defmodule FlowRunner.Spec.Blocks.Log do
  @moduledoc """
  Log things!
  """
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  def evaluate_incoming(%Flow{}, %Block{config: config} = _block, context, %Container{}) do
    {:ok, %Context{context | log: [config["message"] | context.log]}, nil}
  end
end
