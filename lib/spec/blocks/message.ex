defmodule FlowRunner.Spec.Blocks.Message do

    def evaluate(block, context) do
        {:ok, context, block.config["prompt"]}
    end
end