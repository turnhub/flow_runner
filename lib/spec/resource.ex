defmodule FlowRunner.Spec.Resource do
    defstruct [
        :uuid,
        :values
    ]

    alias FlowRunner.Spec.ResourceValue
    def validate(resource) do
        [FlowRunner.Spec.Validate.validate_uuid(resource)] ++
          Enum.concat(Enum.map(resource.values, &ResourceValue.validate/1))
    end

end