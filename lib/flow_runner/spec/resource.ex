defmodule FlowRunner.Spec.Resource do
  @moduledoc """
  Resource stores a piece of content in various languages and modes. Usually associated with a block.
  """
  use FlowRunner.SpecLoader,
    using: [
      values: FlowRunner.Spec.ResourceValue
    ]

  alias FlowRunner.Spec.Resource
  alias FlowRunner.Spec.ResourceValue
  alias FlowRunner.Spec.Flow

  @derive Jason.Encoder
  defstruct uuid: nil,
            values: []

  @type t :: %__MODULE__{
          uuid: String.t(),
          values: [ResourceValue.t()]
        }

  validates(:uuid, presence: true, uuid: [format: :default])

  @spec matching_resource(Resource.t(), language :: String.t(), mode :: String.t(), Flow.t()) ::
          {:ok, ResourceValue.t()} | {:error, String.t()}
  def matching_resource(%Resource{values: resources}, language, mode, flow) do
    # Identify the language object that corresponds to our iso-639-3 code.
    language =
      FlowRunner.language_for_context(
        flow,
        %FlowRunner.Context{language: language}
      )

    # Find resource by language and mode.
    matching_source? = fn resource ->
      resource.language_id == language.id && ResourceValue.supports_mode(resource, mode)
    end

    resource_value = Enum.find(resources, matching_source?)

    if resource_value do
      {:ok, resource_value}
    else
      {:error, "no matching resource"}
    end
  end
end
