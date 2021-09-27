defmodule FlowRunner.Spec.Blocks.Log do
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  def evaluate_incoming(%Flow{}, %Block{config: config} = block, context, %Container{}) do
    {:ok, %Context{context | log: [config["message"] | context.log]}, nil}
  end
end
