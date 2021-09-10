defmodule FlowRunner.Spec.Resource do
  defstruct [
    :uuid,
    :values
  ]

  alias FlowRunner.Spec.ResourceValue
  alias FlowRunner.Spec.Flow

  def validate(resource) do
    [FlowRunner.Spec.Validate.validate_uuid(resource)] ++
      Enum.concat(Enum.map(resource.values, &ResourceValue.validate/1))
  end

  def matching_resource(resource, language, mode, %Flow{languages: languages}) do
    # Identify the language object that corresponds to our iso-639-3 code.
    [language | _] = Enum.filter(languages, &(&1["iso_639_3"] == language))

    # Filter resources by language and mode.
    matching_source? = fn x ->
      x.language_id == language["id"] && ResourceValue.supports_mode(x, mode)
    end

    [resource | _] = Enum.filter(resource.values, matching_source?)
    resource
  end
end
