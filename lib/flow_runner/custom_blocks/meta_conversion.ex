defmodule FlowRunner.CustomBlocks.MetaConversion do
  @moduledoc """
  A block to handle Meta Conversions API events.

  The Conversions API is designed to create a connection between an advertiser's
  marketing data (such as website events, app events, business messaging events
  and offline conversions) from an advertiser's server, website platform, mobile
  app, or CRM to Meta systems that optimize ad targeting, decrease cost per result
  and measure outcomes.

  Rather than maintaining separate connection points for each data source, advertisers
  are able to leverage the Conversions API to send multiple event types and simplify
  their technology stack by establishing a connection between an advertiser's server
  and Meta's Conversions API endpoint.

  The `meta_conversion` block compiles to this FLOIP block.
  The `event_name` and `user_data` config parameters are required.
  All other parameters are optional.
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator

  @impl true
  def validate_config!(%{
        "conversion" =>
          %{
            "event_name" => event_name_uuid,
            "user_data" => user_data_uuid
          } = params
      }) do
    # Extract optional_fields if present (list of resource UUIDs)
    optional_fields = Map.get(params, "optional_fields", [])

    %{
      conversion: %{
        event_name: event_name_uuid,
        user_data: user_data_uuid,
        optional_fields: optional_fields
      }
    }
  end

  @impl true
  def evaluate_incoming(container, flow, block, context) do
    context = %{
      context
      | last_block_uuid: block.uuid,
        # meta conversion messages do not wait for user input
        waiting_for_user_input: false
    }

    {:ok, container, flow, block, context}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
