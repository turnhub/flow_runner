defmodule FlowRunner.Spec.ResourceValue do
    defstruct [
        :language_id,
        :content_type,
        :mime_type,
        :modes,
        :value
    ]

    alias FlowRunner.Spec.ResourceValue

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