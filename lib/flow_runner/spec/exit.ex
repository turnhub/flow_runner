defmodule FlowRunner.Spec.Exit do
  @moduledoc """
  An exit is a potential branch off a FlowRunner.Spec.Block.
  """
  use FlowRunner.SpecLoader

  require Logger

  @derive Jason.Encoder
  defstruct uuid: nil,
            name: nil,
            destination_block: nil,
            semantic_label: nil,
            test: nil,
            default: nil,
            # deprecated in rc2
            config: %{},
            vendor_metadata: %{}

  @type t :: %__MODULE__{
          uuid: String.t(),
          name: String.t(),
          destination_block: String.t() | nil,
          semantic_label: String.t(),
          test: String.t(),
          default: term,
          # deprecated in rc2
          config: map,
          vendor_metadata: map
        }

  validates(:uuid, presence: true, uuid: [format: :default])

  def evaluate(exit, context) do
    test = exit.test || ""

    case FlowRunner.evaluate_expression_block(test, context.vars, skip_context_evaluation?: true) do
      other when not is_boolean(other) ->
        Logger.info(
          "Expression '#{exit.test}' returned #{inspect(other)} when expecting a boolean last_block_uuid=#{context.last_block_uuid}"
        )

        false

      {:error, reason, bad_parts} ->
        Logger.info(
          "Expression '#{exit.test}' returned parsing error #{inspect(reason)} when hit #{inspect(bad_parts)} last_block_uuid=#{context.last_block_uuid}"
        )

        false

      boolean ->
        boolean
    end
  end
end
