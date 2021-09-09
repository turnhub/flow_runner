defmodule FlowRunner.Spec.Container do
    alias FlowRunner.Spec.Container, as: Container
    alias FlowRunner.Spec.Validate, as: Validate

    @derive [Poison.Encoder]
    defstruct [
        :specification_version,
        :uuid,
        :name,
        :description,
        :flows,
        :resources
    ]

    @spec validate(%Container{}) :: :ok | {:error, iodata()} 
    def validate(%Container{} = container) do
        Validate.results([
            validate_specification_version(container),
            Validate.validate_uuid(container)
        ])

    end

    def validate_specification_version(%Container{specification_version: specification_version}) do
        if String.match?(specification_version, ~r/1.0.0-rc[012]/) do
            :ok
        else
            {:error, "invalid specification version '#{specification_version}'"}
        end
    end

end