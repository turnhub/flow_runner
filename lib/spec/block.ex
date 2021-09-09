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
end