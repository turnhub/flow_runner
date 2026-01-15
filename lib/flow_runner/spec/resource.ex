defmodule FlowRunner.Spec.Resource do
  @moduledoc """
  Resource stores a piece of content in various languages and modes. Usually associated with a block.
  """
  use FlowRunner.SpecLoader,
    using: [
      values: FlowRunner.Spec.ResourceValue
    ]

  alias FlowRunner.Spec.Flow
  alias FlowRunner.Spec.Resource
  alias FlowRunner.Spec.ResourceValue

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
  def matching_resource(%Resource{values: resources}, language, mode, %Flow{languages: languages}) do
    # Identify the language object that corresponds to our iso-639-3 code.
    case Enum.filter(languages, &(&1.iso_639_3 == language)) do
      [language | _] ->
        # Filter resources by language and mode.
        matching_source? = fn x ->
          x.language_id == language.id && ResourceValue.supports_mode(x, mode)
        end

        case Enum.filter(resources, matching_source?) do
          [resource_value | _] -> {:ok, resource_value}
          [] -> {:error, "no matching resource"}
        end

      [] ->
        {:error, "no matching languages for resource"}
    end
  end
end
