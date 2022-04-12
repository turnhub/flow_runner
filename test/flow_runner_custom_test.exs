defmodule FlowRunner.CustomTest do
  use ExUnit.Case, async: true
  import FlowRunner.Test.Utils
  doctest FlowRunner.Custom

  # instruct this test module to use the custom runner
  @moduletag flow_runner: FlowRunner.Test.Custom

  setup :with_flow_loader!

  @tag flow: "test/basic.flow"
  test "compile a flow", %{container: container} do
    assert container
  end

  @tag flow: "test/basic.flow"
  test "run a flow", %{container: container} do
    {:ok, context} =
      FlowRunner.create_context(
        container,
        "62d0084d-e88f-48c3-ac64-7a15855f0a43",
        "eng",
        "TEXT"
      )

    {:ok, _context, _, output} = FlowRunner.next_block(container, context)
    assert output.prompt.value == "welcome to this block"
    assert output.prompt.modes == ["TEXT"]
    assert output.prompt.content_type == "TEXT"
  end

  test "fetch a flow", %{flow_runner: flow_runner} do
    {:ok, flow} = apply(flow_runner, :fetch_flow_by_uuid, [nil, "some-id"])

    assert flow.name == "test santiago"
  end
end
