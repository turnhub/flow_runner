defmodule FlowRunner.Spec.ResourceValue do
  @moduledoc """
  ResourceValue is a struct that stores a piece of content for a given language and mode.
  """
  use FlowRunner.SpecLoader

  @derive Jason.Encoder
  defstruct language_id: nil,
            content_type: nil,
            mime_type: nil,
            modes: nil,
            value: nil

  @type t :: %__MODULE__{
          language_id: String.t(),
          content_type: String.t(),
          mime_type: String.t(),
          modes: [String.t()],
          value: String.t()
        }

  validates(:content_type,
    presence: true,
    inclusion: [
      "TEXT",
      "AUDIO",
      "IMAGE",
      "VIDEO"
    ]
  )

  validates(:modes,
    presence: true,
    subset: [
      "TEXT",
      "SMS",
      "USSD",
      "IVR",
      "RICH_MESSAGING",
      "OFFLINE"
    ]
  )

  def supports_mode(resource_value, mode) do
    Enum.count(resource_value.modes, &(&1 == mode)) > 0
  end
end
