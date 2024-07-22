defmodule FlowRunner.CustomBlocks.WhatsAppSendFlow do
  @moduledoc """
  A block to handle the sending of WhatsApp Flows.

  WhatsApp Flows are client side forms that are authored in the
  Facebook Business Manager which can do data collection natively
  on WhatsApp and return the captured data as JSON.

  The `whatsapp_flow` block compiles to this FLOIP block.
  The `id`, `cta`, `screen`, and `text` config parameters are required.

  The `header` and `footer` are optional.
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator

  @impl true
  def validate_config!(%{
        "flow" =>
          %{
            "id" => flow_id,
            "cta" => cta,
            "screen" => screen,
            "text" => text
          } = params
      }) do
    optional_params = read_optional_params(params, [:header, :footer])

    flow_config =
      Map.merge(
        %{
          id: flow_id,
          cta: cta,
          screen: screen,
          text: text
        },
        optional_params
      )

    %{flow: flow_config}
  end

  @doc """
  For the parameter map given, read the optional keys and return a map
  for those values.

  The keys of the map are the keys supplied to this function but converted
  to strings.

  The key only exists on the returned map if a value for the key exists.
  """
  @spec read_optional_params(map, [atom]) :: %{optional(String.t()) => term}
  def read_optional_params(params, keys) do
    Enum.reduce(keys, %{}, fn key, acc ->
      param_key = to_string(key)

      if value = params[param_key] do
        Map.put(acc, key, value)
      else
        acc
      end
    end)
  end

  @impl true
  @decorate trace("DSL.Blocks.WhatsAppSendFlow.evaluate_incoming")
  def evaluate_incoming(container, flow, block, context) do
    context = %{
      context
      | last_block_uuid: block.uuid,
        # flows always wait for input, data collection is their raison d'etre.
        waiting_for_user_input: true
    }

    {:ok, container, flow, block, context}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
