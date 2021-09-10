defmodule FlowRunner.Spec.Container do
    alias FlowRunner.Spec.Container, as: Container
    alias FlowRunner.Spec.Validate, as: Validate
    alias FlowRunner.Spec.Flow
    alias FlowRunner.Spec.Resource

    @derive [Poison.Encoder]
    defstruct [
        :specification_version,
        :uuid,
        :name,
        :description,
        :flows,
        :resources
    ]

    @spec validate(%Container{}) :: list()
    def validate(%Container{} = container) do
        flows = if container.flows == nil do [] else container.flows end
        resources = if container.resources == nil do [] else container.resources end
        [
            validate_specification_version(container),
            Validate.validate_uuid(container)
        ] ++ Enum.concat(Enum.map(flows, &Flow.validate/1)) ++
             Enum.concat(Enum.map(resources, &Resource.validate/1))
    end

    def validate_specification_version(%Container{specification_version: specification_version}) do
        if String.match?(specification_version, ~r/1.0.0-rc[012]/) do
            :ok
        else
            {:error, "invalid specification version '#{specification_version}'"}
        end
    end

    def fetch_resource_by_uuid(%Container{resources: resources}, uuid) do
        [resource | _tail] = Enum.filter(resources, &(&1.uuid == uuid))
        resource
    end
end