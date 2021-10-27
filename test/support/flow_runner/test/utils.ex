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
    if flow_file = Map.get(context, :flow) do
      {:ok, container} =
        "priv/fixtures/"
        |> Path.join(flow_file)
        |> Path.expand()
        |> File.read!()
        |> FlowRunner.compile()

      {:ok, container: container}
    else
      :ok
    end
  end
end