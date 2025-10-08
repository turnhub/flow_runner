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
          variant: String.t() | nil,
          bcp_47: String.t() | nil
        }
end
