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

    def validate(exit) do
        [FlowRunner.Spec.Validate.validate_uuid(exit)]
    end

    def evaluate(exit, context) do
        Expression.evalute(exit.test, context.vars)
    end
end