defmodule FlowRunner.CustomBlocks.UpdateDictionary do
  @moduledoc """
  A custom FLOIP block to update a dictionary contained in the FLOIP context variables.
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator

  @impl true
  @spec validate_config!(map) :: %{
          :reference => String.t(),
          :key => String.t(),
          :value => String.t()
        }
  def validate_config!(%{"reference" => reference, "key" => key, "value" => value}),
    do: %{reference: reference, key: key, value: value}

  @impl true
  @decorate trace("DSL.Blocks.UpdateDictionary.evaluate_incoming")
  def evaluate_incoming(container, flow, block, context) do
    context = %FlowRunner.Context{
      context
      | waiting_for_user_input: false,
        last_block_uuid: block.uuid
    }

    {:ok, container, flow, block, context}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
