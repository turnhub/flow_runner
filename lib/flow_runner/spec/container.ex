defmodule FlowRunner.Spec.Container do
  @moduledoc """
  Container contains a set of flows and resources according to the Flow spec.
  """
  use FlowRunner.SpecLoader,
    using: [
      flows: FlowRunner.Spec.Flow,
      resources: FlowRunner.Spec.Resource
    ]

  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  @derive Jason.Encoder
  defstruct specification_version: nil,
            uuid: nil,
            name: nil,
            description: nil,
            flows: [],
            resources: [],
            vendor_metadata: %{}

  @type t :: %__MODULE__{
          specification_version: String.t(),
          uuid: String.t(),
          name: String.t(),
          description: String.t(),
          flows: [FlowRunner.Spec.Flow.t()],
          resources: [FlowRunner.Spec.Resource.t()],
          vendor_metadata: map
        }

  validates(:specification_version,
    presence: true,
    format: ~r/1.0.0-rc[0123]/
  )

  validates(:uuid, presence: true, uuid: [format: :default])

  def insert_flow_and_resources(
        %Container{} = destination_container,
        %Container{} = source_container,
        %Flow{} = flow
      ) do
    %{
      destination_container
      | flows: destination_container.flows ++ [flow],
        # NOTE: there should be a better way to do this
        resources:
          destination_container.resources ++
            Flow.list_resources_referenced(source_container, flow)
    }
  end

  def fetch_resource_by_uuid(%Container{resources: resources}, uuid) do
    case Enum.find(resources, &(&1.uuid == uuid)) do
      nil -> {:error, "no matching resource"}
      resource -> {:ok, resource}
    end
  end

  def fetch_flow_by_uuid(%Container{flows: flows} = container, uuid) do
    case Enum.find(flows, &(&1.uuid == uuid)) do
      nil -> {:error, "no matching flow"}
      flow -> {:ok, container, flow}
    end
  end
end
