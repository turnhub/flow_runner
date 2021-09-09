defmodule FlowRunner.Spec.Container do
    @derive [Poison.Encoder]
    defstruct [
        :specification_version,
        :uuid,
        :name,
        :description,
        :flows,
        :resources
    ]
end