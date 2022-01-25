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

  @derive {Jason.Encoder, except: [:blocks_module]}
  defstruct specification_version: nil,
            uuid: nil,
            name: nil,
            description: nil,
            flows: [],
            resources: [],
            vendor_metadata: %{},
            blocks_module: FlowRunner.DefaultBlocks

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

  @impl true
  def validate!(blocks_module, data) do
    validated = super(blocks_module, data)
    Map.put(validated, :blocks_module, blocks_module)
  end

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
end
