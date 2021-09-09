defmodule FlowRunner.Spec.Exit do
    defstruct [
        :uuid,
        :name,
        :destination_block,
        :semantic_label,
        :test,
        :default,
        :config
    ]
end