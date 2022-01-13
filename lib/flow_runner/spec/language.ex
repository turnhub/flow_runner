defmodule FlowRunner.Spec.Language do
  @moduledoc """
  Languages are ISO-639-3 codes with some extra metadata
  """

  use FlowRunner.SpecLoader

  @derive Jason.Encoder
  defstruct [:id, :iso_639_3, :label, :variant, :bcp_47]

  @type t :: %__MODULE__{
          id: String.t(),
          iso_639_3: String.t(),
          label: String.t(),
          variant: String.t(),
          bcp_47: String.t()
        }

  validates(:id, presence: true)
  validates(:iso_639_3, presence: true, format: ~r/[a-zA-Z]{3}/)
  validates(:label, presence: true)
end
