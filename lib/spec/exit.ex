defmodule FlowRunner.Spec.Exit do
  @moduledoc """
  An exit is a potential branch off a FlowRunner.Spec.Block.
  """
  use FlowRunner.SpecLoader

  @type t :: %__MODULE__{
          uuid: String.t(),
          name: String.t(),
          destination_block: String.t(),
          semantic_label: String.t(),
          test: String.t(),
          default: term,
          config: map
        }

  defstruct [
    :uuid,
    :name,
    :destination_block,
    :semantic_label,
    :test,
    :default,
    :config
  ]

  def validate(exit) do
    [FlowRunner.Spec.Validate.validate_uuid(exit)]
  end

  def evaluate(exit, context) do
    if exit.test != nil && exit.test != "" do
      {:ok, truthy} = Expression.evaluate("@(#{exit.test})", context.vars)
      truthy || exit.default
    else
      exit.default
    end
  end
end
