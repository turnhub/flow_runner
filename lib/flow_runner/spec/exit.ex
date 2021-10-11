defmodule FlowRunner.Spec.Exit do
  @moduledoc """
  An exit is a potential branch off a FlowRunner.Spec.Block.
  """
  use FlowRunner.SpecLoader

  @derive Jason.Encoder
  defstruct uuid: nil,
            name: nil,
            destination_block: nil,
            semantic_label: nil,
            test: nil,
            default: nil,
            config: %{},
            vendor_metadata: %{}

  @type t :: %__MODULE__{
          uuid: String.t(),
          name: String.t(),
          destination_block: String.t(),
          semantic_label: String.t(),
          test: String.t(),
          default: term,
          config: map,
          vendor_metadata: map
        }

  validates(:uuid, presence: true, uuid: [format: :default])

  def evaluate(exit, context) do
    if exit.test != nil && exit.test != "" do
      {:ok, truthy} = Expression.evaluate_block(exit.test, context.vars)

      truthy || exit.default
    else
      exit.default
    end
  end
end
