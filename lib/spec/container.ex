defmodule FlowRunner.Spec.Container do
  @moduledoc """
  Container contains a set of flows and resources according to the Flow spec.
  """
  use FlowRunner.SpecLoader,
    manual: %{
      "flows" => FlowRunner.Spec.Flow,
      "resources" => FlowRunner.Spec.Resource
    }

  alias FlowRunner.Spec.Container, as: Container
  alias FlowRunner.Spec.Validate, as: Validate
  alias FlowRunner.Spec.Flow
  alias FlowRunner.Spec.Resource

  @type t :: %__MODULE__{
          specification_version: String.t(),
          uuid: String.t(),
          name: String.t(),
          description: String.t(),
          flows: [FlowRunner.Spec.Flow.t()],
          resources: [FlowRunner.Spec.Resource.t()]
        }

  @derive [Poison.Encoder]
  defstruct specification_version: nil,
            uuid: nil,
            name: nil,
            description: nil,
            flows: [],
            resources: []

  def fetch_resource_by_uuid(%Container{resources: resources}, uuid) do
    case Enum.find(resources, &(&1.uuid == uuid)) do
      nil -> {:error, "no matching resource"}
      resource -> {:ok, resource}
    end
  end

  def fetch_flow_by_uuid(%Container{flows: flows}, uuid) do
    case Enum.find(flows, &(&1.uuid == uuid)) do
      nil -> {:error, "no matching flow"}
      flow -> {:ok, flow}
    end
  end

  @spec validate(%Container{}) :: list()
  def validate(%Container{} = container) do
    [
      validate_specification_version(container),
      Validate.validate_uuid(container)
    ] ++
      Enum.concat(Enum.map(container.flows, &Flow.validate/1)) ++
      Enum.concat(Enum.map(container.resources, &Resource.validate/1))
  end

  def validate_specification_version(%Container{specification_version: specification_version}) do
    if specification_version && String.match?(specification_version, ~r/1.0.0-rc[012]/) do
      :ok
    else
      {:error, "invalid specification version '#{specification_version}'"}
    end
  end
end
