defmodule RunnerTest do
  use ExUnit.Case, async: true

  setup do
    original_module = Application.get_env(:flow_runner, :blocks_module)
    Application.put_env(:flow_runner, :blocks_module, RunnerTest.CustomBlocks)
    on_exit(fn -> Application.put_env(:flow_runner, :blocks_module, original_module) end)
  end

  defmodule CustomBlocks do
    @behaviour FlowRunner.Blocks

    @impl true
    def blocks do
      Map.merge(FlowRunner.Blocks.blocks(), %{
        "Io.Turn.Custom" => FlowRunner.Spec.Blocks.Message
      })
    end
  end

  defp replace_type(flow_file, from, to) do
    json =
      "priv/fixtures/"
      |> Path.join(flow_file)
      |> Path.expand()
      |> File.read!()
      |> String.replace(from, to)
      |> Jason.decode!()

    FlowRunner.compile!(CustomBlocks, json)
  end

  test "run a flow with a custom block type" do
    container = replace_type("test/basic.flow", "MobilePrimitives.Message", "Io.Turn.Custom")
    assert FlowRunner.blocks_module() == CustomBlocks

    {:ok, context} =
      FlowRunner.create_context(
        container,
        "62d0084d-e88f-48c3-ac64-7a15855f0a43",
        "eng",
        "TEXT"
      )

    {:ok, container, flow, block, context} = FlowRunner.next_block(container, context)
    assert block.type == "Io.Turn.Custom"
    assert %{prompt: resource_uuid} = block.config
    assert {:ok, resource} = FlowRunner.fetch_resource_by_uuid(container, resource_uuid)

    assert {:ok, resource_value} =
             FlowRunner.fetch_resource_value(resource, context.language, context.mode, flow)

    assert resource_value.value == "welcome to this block"
    assert resource_value.modes == ["TEXT"]
    assert resource_value.content_type == "TEXT"
  end

  test "custom blocks attribute shouldn't be encoded in JSON" do
    container = replace_type("test/basic.flow", "MobilePrimitives.Message", "Io.Turn.Custom")
    assert FlowRunner.blocks_module() == CustomBlocks

    json = Jason.encode!(container)
    assert String.contains?(json, "Io.Turn.Custom")
    refute String.contains?(json, "CustomBlocks")
    refute String.contains?(json, "blocks_module")
  end
end
