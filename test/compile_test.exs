defmodule FlowRunner.CompileTest do
  use ExUnit.Case
  doctest FlowRunner

  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Exit
  alias FlowRunner.Spec.Flow

  test "compiles" do
    {:ok, container} = FlowRunner.compile(
      ~s({"specification_version": "1",
          "flows":[{
            "uuid":"uuid",
            "blocks":[{
              "name": "test block",
              "exits": [{"name": "test exit"}]
            }]
          }]}))
    assert container == %Container{
      specification_version: "1",
      flows: [
        %Flow{
          uuid: "uuid",
          blocks: [
            %Block{
              name: "test block",
              exits: [
                %Exit{
                  name: "test exit"
                }
              ]
            }
          ]
        }
      ]
    }
  end
end
