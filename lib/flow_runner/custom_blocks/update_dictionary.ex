defmodule FlowRunner.CustomBlocks.UpdateDictionary do
  @moduledoc """
  A custom FLOIP block to update a dictionary contained in the FLOIP context variables.
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  use FlowRunner.BlockAutodoc

  @block_category "data"
  @block_doc type: "Io.Turn.UpdateDictionary",
             dsl_name: "update_dictionary()",
             description: "Updates a key-value pair in a dictionary variable.",
             config: %{
               "reference" => %{
                 type: "string",
                 required: true,
                 description: "The dictionary variable to update"
               },
               "key" => %{type: "string", required: true, description: "The key to set"},
               "value" => %{
                 type: "expression",
                 required: true,
                 description: "The value expression to evaluate and store"
               }
             },
             example: """
             card Deposit do
               update_dictionary(account, "balance", account.balance + 1)
               text("You've deposited $1")
             end
             """

  @impl true
  @spec validate_config!(map) :: %{
          :reference => String.t(),
          :key => String.t(),
          :value => String.t()
        }
  def validate_config!(%{"reference" => reference, "key" => key, "value" => value}),
    do: %{reference: reference, key: key, value: value}

  @impl true
  @decorate with_span("DSL.Blocks.UpdateDictionary.evaluate_incoming")
  def evaluate_incoming(container, flow, block, %FlowRunner.Context{} = context) do
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
