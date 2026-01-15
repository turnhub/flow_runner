defmodule FlowRunner.CustomBlocks.Webhook do
  @moduledoc """
  A custom Webhook block type for Turn's Build functionality.

  The FLOIP spec originally did not specify a Webhook block and so we had
  to roll our own until it does.

  Since rc4 it does Turn had already implemented this. We'll look at moving
  to rc4 at some stage but not right now.

  Because of historical RapidPro context informing the FLOIP design, there's
  an assumption for some systems that the `webhook` key in the context's
  variables always contains the last called webhook response.

  This may be useful as a default when a FLOIP only does a single webhook call but it
  ends up being confusing when there are multiple webhook calls that can happen.

  To retain some compatibility we always write the results under the `webhook` key
  in the context in addition to the key of the current block.
  """
  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  use Tesla
  require Logger
  require OpenTelemetry.Tracer, as: Tracer

  @default_timeout :timer.seconds(5)
  @maximum_timeout :timer.seconds(20)
  @default_cache_ttl :timer.minutes(1)

  defstruct [
    :body,
    :method,
    :url,
    query: [],
    headers: [],
    cache_ttl: @default_cache_ttl,
    mode: "sync",
    timeout: @default_timeout
  ]

  def default_timeout, do: @default_timeout

  @impl true
  # credo:disable-for-next-line
  def validate_config!(
        %{
          "url" => url,
          "method" => method,
          "headers" => headers,
          "query" => query,
          "body" => body,
          "timeout" => timeout,
          "mode" => mode
        } = webhook
      )
      when method in ["HEAD", "GET", "DELETE", "TRACE", "OPTIONS", "POST", "PUT", "PATCH"] and
             mode in ["sync", "async"] and
             is_list(headers) and
             is_number(timeout) and
             (is_list(query) or is_nil(query)) and
             is_binary(url) do
    # We have some FLOIP specs in the db that have a URL that's invalid. Any new FLOIP spec
    # is guarded against this with validation as the stack level.
    # When we do find an invalid URL, rather replace it with example.org than cause a runtime
    # crash
    url =
      if safe_url?(url) do
        url
      else
        Logger.warning(
          "Invalid configuration for webhook, replacing invalid URL #{inspect(url)} with \"https://example.org\" to prevent a runtime crash"
        )

        # Using example.org, see https://www.iana.org/domains/reserved
        "https://example.org/"
      end

    %__MODULE__{
      url: url,
      method: method,
      headers: headers,
      # backwards compatibility, because there are entries in the db where query is nil
      query: query || [],
      body: body,
      # We set a maximum timeout value of 20 seconds here for performance reasons.
      # External services should not be taking longer to respond.
      # Users are also warned about this in validation_messages.
      # We also include a floor of a 10the of a second so that we handle unreasonably
      # low wait times as well.
      timeout: max(min(timeout, @maximum_timeout), 100),
      cache_ttl: Map.get(webhook, "cache_ttl") || @default_cache_ttl,
      mode: mode
    }
    |> Map.from_struct()
  end

  def validate_config!(config), do: raise("Invalid configuration for webhook: #{inspect(config)}")

  @doc """
  Naive check to see if a URL is safe or not by checking if the domain points
  at IP addresses for reserved internal networks or not.

  """
  def safe_url?(url) do
    with parsed_url
         when not is_nil(parsed_url.host) <-
           URI.parse(url),
         {:ok, ip_tuple} <- :inet.getaddr(to_charlist(parsed_url.host), :inet) do
      not Iptools.is_reserved?(Enum.join(Tuple.to_list(ip_tuple), "."))
    else
      _all_other_results ->
        false
    end
  end

  defp group_by_key(enumerable) do
    Enum.reduce(enumerable, %{}, fn {key, value}, acc ->
      string_key = to_string(key)
      value_list = Map.get(acc, string_key) || []
      Map.put(acc, string_key, [value | value_list])
    end)
  end

  def create_client(block, headers) do
    Tesla.client([
      {Tesla.Middleware.Headers, headers},
      {Tesla.Middleware.Timeout, timeout: block.config.timeout},
      Tesla.Middleware.JSON
    ])
  end

  @spec process_webhook(FlowRunner.Spec.Block.t(), FlowRunner.Context.t(), parameters :: map) ::
          map
  def process_webhook(%{config: %{mode: "sync"}} = block, context, parameters),
    do: process_sync_webhook(block, context, parameters)

  def process_webhook(block, context, parameters),
    do: process_async_webhook(block, context, parameters)

  def process_sync_webhook(block, _context, %{
        method: method,
        url: url,
        body: body,
        query: query,
        headers: headers
      }) do
    client = create_client(block, headers)

    Tracer.with_span "build.blocks.webhook.request" do
      request(client, method: httpc_method(method), url: url, body: body, query: query)
      |> process_response(block)
    end
  end

  def httpc_method("HEAD"), do: :head
  def httpc_method("GET"), do: :get
  def httpc_method("PUT"), do: :put
  def httpc_method("PATCH"), do: :patch
  def httpc_method("POST"), do: :post
  def httpc_method("TRACE"), do: :trace
  def httpc_method("OPTIONS"), do: :options
  def httpc_method("DELETE"), do: :delete

  def process_async_webhook(block, _context, %{
        method: method,
        url: url,
        body: body,
        query: query,
        headers: headers
      }) do
    client = create_client(block, headers)
    # Just fire the task and forget about it
    {:ok, _pid} =
      Task.start(fn ->
        request(client, method: method, url: url, body: body, query: query)
      end)

    %{
      "url" => url,
      "mode" => block.config.mode
    }
  end

  def evaluate_webhook_parameters(block, context) do
    # We may need access to privileged auth tokens here since webhooks could
    # potentially need them to make external calls.
    #
    # The implementation of this has been left out in the OSS version of
    # this webhooks module as we'll need to refactor it to allow this implementation
    # to be configurable in code
    privileged_context = context.vars

    callbacks_module =
      Application.get_env(
        :flow_runner,
        :expression_callbacks_module,
        Expression.Callbacks.Standard
      )

    evaluate_as_string! =
      &Expression.evaluate_as_string!(
        to_string(&1),
        privileged_context,
        callbacks_module
      )

    evaluate_key_pairs = fn pairs ->
      Enum.map(pairs, fn [key, value] ->
        {evaluate_as_string!.(key), evaluate_as_string!.(value)}
      end)
    end

    url = evaluate_as_string!.(block.config.url)

    headers = evaluate_key_pairs.(block.config.headers)
    query = evaluate_key_pairs.(block.config.query)

    body =
      cond do
        is_list(block.config.body) ->
          URI.encode_query(evaluate_key_pairs.(block.config.body))

        is_binary(block.config.body) ->
          evaluate_as_string!.(block.config.body)

        true ->
          block.config.body
      end

    %{method: block.config.method, url: url, headers: headers, body: body, query: query}
  end

  @impl true
  @decorate with_span("build.blocks.webhook.evaluate_incoming")
  def evaluate_incoming(container, flow, block, context) do
    webhook_parameters = evaluate_webhook_parameters(block, context)

    webhook_context =
      block
      |> process_webhook(context, webhook_parameters)

    context_vars = %{
      "webhook" => webhook_context,
      block.name => webhook_context
    }

    {:ok, container, flow, block,
     %{
       context
       | waiting_for_user_input: false,
         last_block_uuid: block.uuid,
         vars: Map.merge(context.vars, context_vars)
     }}
  end

  @doc """
  Process the response received from a call to an external HTTP API.
  Provides somewhat graceful fallback handling when the remote endpoint
  doesn't respond within adequate time.

  If there's simply no response, in the event of a connection error or a timeout
  then we'll construct a response to the best of our abilities to allow
  the stack to continue, delegating responsibility for the handling of this error
  case to the stack author.

  This returns the context map that is added to the flow context for this block.
  """
  @spec process_response(Tesla.Env.result(), FlowRunner.Spec.Block.t()) :: map()
  def process_response(
        {:ok, %Tesla.Env{body: body, status: status, headers: headers, query: query}},
        block
      ),
      do: %{
        "url" => block.config.url,
        "status" => status,
        "body" => body,
        "query" => group_by_key(query),
        "mode" => block.config.mode,
        "headers" => group_by_key(headers)
      }

  def process_response(
        {:error, %Tesla.Env{body: body, status: status, headers: headers, query: query}},
        block
      ),
      do: %{
        "url" => block.config.url,
        "status" => status,
        "body" => body,
        "query" => group_by_key(query),
        "mode" => block.config.mode,
        "headers" => group_by_key(headers)
      }

  def process_response(
        {:error,
         {Tesla.Middleware.JSON, :decode, %Jason.DecodeError{data: "Internal Server Error"}}},
        block
      ) do
    %{
      "url" => block.config.url,
      "status" => 500,
      "body" => block.config.body,
      "query" => block.config.query,
      "mode" => block.config.mode,
      "headers" => block.config.headers
    }
  end

  def process_response(
        {:error, {Tesla.Middleware.JSON, :decode, %Jason.DecodeError{data: non_json_data}}},
        block
      ) do
    %{
      "url" => block.config.url,
      "status" => 200,
      "body" => non_json_data,
      "query" => block.config.query,
      "mode" => block.config.mode,
      "headers" => block.config.headers
    }
  end

  # This is a connection error
  def process_response({:error, reason}, block) when is_atom(reason) or is_binary(reason),
    do: %{
      "url" => block.config.url,
      "status" => nil,
      "body" => "ERROR: #{reason}",
      "query" => group_by_key(Enum.map(block.config.query, &List.to_tuple/1)),
      "mode" => block.config.mode,
      "headers" => group_by_key(Enum.map(block.config.headers, &List.to_tuple/1))
    }

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
