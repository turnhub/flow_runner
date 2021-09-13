defmodule FlowRunner.Spec.Resource do
  @moduledoc """
  Resource stores a piece of content in various languages and modes. Usually associated with a block.
  """
  alias FlowRunner.Spec.Resource
  alias FlowRunner.Spec.ResourceValue
  alias FlowRunner.Spec.Flow

  defstruct [
    :uuid,
    :values
  ]

  def validate(resource) do
    [FlowRunner.Spec.Validate.validate_uuid(resource)] ++
      Enum.concat(Enum.map(resource.values, &ResourceValue.validate/1))
  end

  @spec matching_resource(%Resource{}, iodata(), iodata(), %Flow{}) ::
          {:ok, %ResourceValue{}} | {:error, iodata()}
  def matching_resource(%Resource{values: resources}, language, mode, %Flow{languages: languages}) do
    # Identify the language object that corresponds to our iso-639-3 code.
    languages = Enum.filter(languages, &(&1["iso_639_3"] == language))

    if length(languages) > 0 do
      [language | _] = languages
      # Filter resources by language and mode.
      matching_source? = fn x ->
        x.language_id == language["id"] && ResourceValue.supports_mode(x, mode)
      end

      resourceValues = Enum.filter(resources, matching_source?)

      if length(resourceValues) > 0 do
        [resourceValue | _] = resourceValues
        {:ok, resourceValue}
      else
        {:error, "no matching resource"}
      end
    else
      {:error, "no matching languages for resource"}
    end
  end
end
