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
            config: %{}

  @type t :: %__MODULE__{
          uuid: String.t(),
          name: String.t(),
          destination_block: String.t(),
          semantic_label: String.t(),
          test: String.t(),
          default: term,
          config: map
        }

  validates(:uuid, presence: true, uuid: [format: :default])

  def evaluate(exit, context) do
    if exit.test != nil && exit.test != "" do
      case Expression.evaluate_block(exit.test, context.vars) do
        {:ok, truthy} ->
          truthy || exit.default

        {:error, reason} ->
          Logger.info(
            "Expression '#{exit.test}' failed with #{reason} last_block_uuid=#{context.last_block_uuid}"
          )

          exit.default
      end
    else
      exit.default
    end
  end
end
