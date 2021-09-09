defmodule FlowRunner.CompileTest do
  use ExUnit.Case
  doctest FlowRunner

  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Exit
  alias FlowRunner.Spec.Flow

  test "compiles" do
    {:ok, container} = FlowRunner.compile(
      ~s({"specification_version": "1.0.0-rc1",
          "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
          "flows":[{
            "uuid":"3666a05d-3792-482b-8f7f-9e2472e4f027",
            "blocks":[{
              "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
              "name": "test block",
              "exits": [{"name": "test exit"}]
            }]
          }]}))
    assert container == %Container{
      specification_version: "1.0.0-rc1",
      uuid: "3666a05d-3792-482b-8f7f-9e2472e4f027",
      flows: [
        %Flow{
          uuid: "3666a05d-3792-482b-8f7f-9e2472e4f027",
          blocks: [
            %Block{
              uuid: "3666a05d-3792-482b-8f7f-9e2472e4f027",
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
