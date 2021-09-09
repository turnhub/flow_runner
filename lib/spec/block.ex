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

    alias FlowRunner.Spec.Exit
    alias FlowRunner.Spec.Validate

    def validate(block) do
        exits = if block.exits != nil do block.exits else [] end
        [
            Validate.validate_uuid(block),
        ] ++ Enum.concat(Enum.map(exits, &Exit.validate/1))
    end
end