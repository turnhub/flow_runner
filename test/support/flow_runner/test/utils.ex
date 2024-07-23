defmodule FlowRunner.Test.Utils do
  @moduledoc """
  A collection of helper functions that can be
  used as a `setup` callback in ExUnit tests.
  """

  @doc """
  A helper function to make it easier to load
  flow JSON specification files from disk.

  Any test tagged with `flow: path/to/file.json` will
  result in that flow being compiled and made availabe
  within the test context under the `container` key

  ## Example

    setup :with_flow_loader!

    @tag flow: "path/to/json.flow"
    test "some flow", %{container: container} do
      assert container
    end

  """
  def with_flow_loader!(context) do
    implementation = Map.get(context, :flow_runner, FlowRunner)
    blocks_module = Map.get(context, :blocks_module, FlowRunner.Blocks)

    if flow_spec = Map.get(context, :flow) do
      {container, bypasses} = load_container(flow_spec, implementation, blocks_module)
      {:ok, container: container, container_bypasses: bypasses}
    else
      :ok
    end
  end

  def load_container(flow_file, implementation, blocks_module) when is_binary(flow_file),
    do: load_container({flow_file, []}, implementation, blocks_module)

  def load_container({flow_file, bypasses}, implementation, blocks_module) do
    json =
      "priv/fixtures/"
      |> Path.join(flow_file)
      |> Path.expand()
      |> File.read!()
      |> Jason.decode!()

    implementation
    |> apply(:compile!, [blocks_module, json])
    |> create_webhook_bypasses(bypasses)
  end

  def create_webhook_bypasses(container, bypasses) do
    bypasses = Enum.map(bypasses, fn domain -> {domain, Bypass.open()} end)
    flows = Enum.map(container.flows, &create_webhook_bypasses_for_flow(&1, bypasses))
    {%{container | flows: flows}, bypasses}
  end

  def create_webhook_bypasses_for_flow(flow, bypasses) do
    blocks = Enum.map(flow.blocks, &create_webhook_bypass_for_block(&1, bypasses))
    %{flow | blocks: blocks}
  end

  def create_webhook_bypass_for_block(%{type: "Io.Turn.Webhook"} = block, bypasses) do
    bypass =
      Enum.find_value(bypasses, fn {domain, bypass} ->
        if(block.config.url =~ domain, do: bypass)
      end)

    config =
      if bypass do
        patched_uri =
          block.config.url
          |> URI.parse()
          |> Map.put(:scheme, "http")
          |> Map.put(:host, "127.0.0.1")
          |> Map.put(:port, bypass.port)
          |> URI.to_string()

        Map.put(block.config, :url, patched_uri)
      else
        block.config
      end

    %{block | config: config}
  end

  def create_webhook_bypass_for_block(block, _bypasses), do: block

  def resource_value(container, flow, context, resource_uuid) do
    {:ok, resource} = FlowRunner.fetch_resource_by_uuid(container, resource_uuid)
    language = FlowRunner.language_for_context(flow, context)

    {:ok, resource_value} =
      FlowRunner.fetch_resource_value(resource, language.iso_639_3, context.mode, flow)

    resource_value.value
  end
end
