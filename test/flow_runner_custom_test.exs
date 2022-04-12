defmodule FlowRunner.CustomTest.Runner do
  use FlowRunner.Custom

  def fetch_flow_by_uuid(_container, _uuid) do
    # custom_lookup_in_db(uuid)
  end
end

defmodule FlowRunner.CustomTest do
  use ExUnit.Case, async: true
  import FlowRunner.Test.Utils
  doctest FlowRunner.Custom

  # instruct this test module to use the custom runner
  @moduletag flow_runner: FlowRunner.CustomTest.Runner

  setup :with_flow_loader!

  @tag flow: "test/basic.flow"
  test "compile a flow", %{container: container} do
    assert container
  end
end
