defmodule FlowRunner.Spec.Block do
    @derive [Poison.Encoder]
    defstruct [
        :uuid,
        :name,
        :label,
        :semantic_label,
        :tags,
        :vendor_metadata,
        :ui_metadata,
        :type,
        :config,
        :exits
    ]

    alias FlowRunner.Context
    alias FlowRunner.Spec.Exit
    alias FlowRunner.Spec.Validate

    def validate(block) do
        exits = if block.exits != nil do block.exits else [] end
        [
            Validate.validate_uuid(block),
        ] ++ Enum.concat(Enum.map(exits, &Exit.validate/1))
    end

    def evaluate_user_input(_block, context, _user_input) do
        # TODO set the thing that needs setting.
        %Context{context | waiting_for_user_input: false}
    end

    def evaluate_block(flow, block, context) do
        # TODO There has to be a better way...
        {:ok, context, resource_id} = case block.type do
            "MobilePrimitives.Message" -> FlowRunner.Spec.Blocks.Message.evaluate(block, context)
            unknown -> {:error, "unknown block type #{unknown}"}
        end
    end

    @spec evaluate_exits(%FlowRunner.Spec.Block{}, %FlowRunner.Context{}) :: %FlowRunner.Spec.Exit{}
    def evaluate_exits(block, %Context{} = context) do
        truthy_exits = Enum.filter(block.exits, &(&1.default || Exit.evaluate(&1, context)))
        if length(truthy_exits) > 0 do
            {:ok, Enum.at(truthy_exits, 0)}
        else
            {:error, "no exit evaluated to true"}
        end
    end
end