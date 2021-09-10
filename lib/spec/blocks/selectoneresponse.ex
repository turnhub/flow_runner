defmodule FlowRunner.Spec.Block.SelectOneResponse do

    def evaluate(block, context) do
        {:ok, context, block.config["prompt"]}
    end
end