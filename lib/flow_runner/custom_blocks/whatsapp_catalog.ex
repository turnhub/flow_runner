defmodule FlowRunner.CustomBlocks.WhatsAppCatalog do
  @moduledoc """
  A block to handle WhatsApp catalog messages.

  WhatsApp catalog messages allow businesses to showcase their products
  or services within the WhatsApp conversation. This block handles the
  display of catalog information with optional footer text.

  The `whatsapp_catalog` block compiles to this FLOIP block.
  The `text` config parameter is required for the catalog body text.
  The `footer` parameter is optional.
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator

  @impl true
  def validate_config!(%{
        "catalog" =>
          %{
            "text" => text
          } = params
      }) do
    optional_params = read_optional_params(params, [:footer])

    catalog_config =
      Map.merge(
        %{
          text: text
        },
        optional_params
      )

    %{catalog: catalog_config}
  end

  @doc """
  For the parameter map given, read the optional keys and return a map
  for those values.

  The keys of the map are the keys supplied to this function but converted
  to atoms.

  The key only exists on the returned map if a value for the key exists.
  """
  @spec read_optional_params(map, [atom]) :: %{optional(atom) => term}
  def read_optional_params(params, keys) do
    Enum.reduce(keys, %{}, fn key, acc ->
      param_key = to_string(key)

      if Map.has_key?(params, param_key) do
        Map.put(acc, key, params[param_key])
      else
        acc
      end
    end)
  end

  @impl true
  def evaluate_incoming(container, flow, block, context) do
    context = %{
      context
      | last_block_uuid: block.uuid,
        # catalog messages wait for user input (place order)
        waiting_for_user_input: true
    }

    {:ok, container, flow, block, context}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
