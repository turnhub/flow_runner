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
  The `event_name` config parameter is required and should be provided as a string
  expression (e.g., "Purchase" or "@(contact.event_type)").
  The `user_data` parameter is required and should be a map, keyword list, or JSON string
  of key-value pairs where values are evaluated as expressions (e.g., %{email: "@email", phone: "@phone"}
  or "{\"email\":\"@email\",\"phone\":\"@phone\"}").
  The `optional_fields` parameter is optional and should be a map, keyword list, or JSON string
  of key-value pairs where values are evaluated as expressions (e.g., %{event_id: "123",
  event_source_url: "@url"} or "{\"event_id\":\"123\",\"event_source_url\":\"@url\"}").
  """

  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  use FlowRunner.BlockAutodoc

  @block_category "integration"
  @block_doc type: "Io.Turn.MetaConversion",
             dsl_name: "conversion()",
             description:
               "Sends conversion events to Meta's Conversions API for ad optimization and measurement.",
             config: %{
               "conversion.event_name" => %{
                 type: "string",
                 required: true,
                 description: "The conversion event name (e.g., \"Purchase\", \"Lead\")"
               },
               "conversion.user_data" => %{
                 type: "map",
                 required: true,
                 description: "User data for matching (email, phone, etc.)"
               },
               "conversion.optional_fields" => %{
                 type: "map",
                 required: false,
                 description: "Optional fields like event_id, event_source_url"
               }
             },
             example: """
             card Card do
               conversion("Purchase", phone: "+1234567890", email: "user@example.com")
             end
             """

  @impl true
  def validate_config!(%{
        "conversion" =>
          %{
            "event_name" => event_name,
            "user_data" => user_data
          } = params
      })
      when user_data != nil and user_data != "" do
    # Extract optional_fields if present (default to empty map)
    optional_fields = Map.get(params, "optional_fields", %{})

    %{
      conversion: %{
        event_name: event_name,
        user_data: user_data,
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
