defmodule FlowTest do
  use ExUnit.Case
  doctest FlowRunner.Spec.Flow

  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Flow

  test "fetch block" do
    flow = %Flow{
      blocks: [
        %Block{
          name: "t2",
          uuid: "0ff0a1ab-ea0d-4f2c-bc87-59df685f220e"
        },
        %Block{
          name: "t1",
          uuid: "0019d7e9-e715-489e-bbdb-984399a0f8e5"
        }
      ]
    }

    assert {:ok, %Block{name: "t1"}} =
             Flow.fetch_block(flow, "0019d7e9-e715-489e-bbdb-984399a0f8e5")

    assert {:error, _} = Flow.fetch_block(flow, "non-existent")

    empty_flow = %Flow{}
    assert {:error, _} = Flow.fetch_block(empty_flow, "anything")
  end
end
