defmodule FlowRunner.Spec.ResourceValue do
  @moduledoc """
  ResourceValue is a struct that stores a piece of content for a given language and mode.
  """
  use FlowRunner.SpecLoader
  alias FlowRunner.Spec.ResourceValue

  @type t :: %__MODULE__{}

  defstruct [
    :language_id,
    :content_type,
    :mime_type,
    :modes,
    :value
  ]

  def supports_mode(resource_value, mode) do
    Enum.count(resource_value.modes, &(&1 == mode)) > 0
  end

  def validate(resource) do
    [validate_content_type(resource)]
  end

  def validate_content_type(%ResourceValue{content_type: "TEXT"}), do: :ok
  def validate_content_type(%ResourceValue{content_type: "AUDIO"}), do: :ok
  def validate_content_type(%ResourceValue{content_type: "IMAGE"}), do: :ok
  def validate_content_type(%ResourceValue{content_type: "VIDEO"}), do: :ok

  def validate_content_type(%ResourceValue{content_type: content_type}) do
    {:error, "unknown content_type #{content_type}"}
  end
end
