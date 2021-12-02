defmodule FlowRunner.CompileTest do
  use ExUnit.Case
  doctest FlowRunner

  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Exit
  alias FlowRunner.Spec.Flow

  test "compiles" do
    {:ok, container} = FlowRunner.compile(~s({"specification_version": "1.0.0-rc1",
          "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
          "flows":[{
            "uuid":"3666a05d-3792-482b-8f7f-9e2472e4f027",
            "blocks":[{
              "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
              "name": "test block",
              "type": "Core.Case",
              "exits": [{
                "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
                "name": "test exit"
              }]
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
                     type: "Core.Case",
                     exits: [
                       %Exit{
                         uuid: "3666a05d-3792-482b-8f7f-9e2472e4f027",
                         name: "test exit"
                       }
                     ]
                   }
                 ]
               }
             ]
           }
  end

  test "validates for single default exits" do
    {:error, "Blocks can only have 1 default exit, found: \"default exit 1\", \"default exit 2\""} =
      FlowRunner.compile(%{
        "specification_version" => "1.0.0-rc1",
        "uuid" => "3666a05d-3792-482b-8f7f-9e2472e4f027",
        "flows" => [
          %{
            "uuid" => "3666a05d-3792-482b-8f7f-9e2472e4f027",
            "blocks" => [
              %{
                "uuid" => "3666a05d-3792-482b-8f7f-9e2472e4f027",
                "name" => "test block",
                "type" => "Core.Case",
                "exits" => [
                  %{
                    "uuid" => "3666a05d-3792-482b-8f7f-9e2472e4f027",
                    "name" => "test exit"
                  },
                  %{
                    "uuid" => "3666a05d-3792-482b-8f7f-9e2472e4f028",
                    "name" => "default exit 1",
                    "default" => true
                  },
                  %{
                    "uuid" => "3666a05d-3792-482b-8f7f-9e2472e4f029",
                    "name" => "default exit 2",
                    "default" => true
                  }
                ]
              }
            ]
          }
        ]
      })
  end

  test "validates flow" do
    # invalid flow UUID
    {:error, _} = FlowRunner.compile(~s({"specification_version": "1.0.0-rc1",
          "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
          "flows":[{
            "uuid":"",
            "blocks":[]
          }]}))
  end

  test "validates blocks" do
    # Missing 'type' field on block.
    {:error, _} = FlowRunner.compile(~s({"specification_version": "1.0.0-rc1",
          "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
          "flows":[{
            "uuid":"3666a05d-3792-482b-8f7f-9e2472e4f027",
            "blocks":[{
              "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
              "name": "test block",
              "exits": [{
                "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
                "name": "test exit"
              }]
            }]
          }]}))
    {:ok, _} = FlowRunner.compile(~s({"specification_version": "1.0.0-rc1",
          "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
          "flows":[{
            "uuid":"3666a05d-3792-482b-8f7f-9e2472e4f027",
            "blocks":[{
              "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
              "name": "test block",
              "type": "Core.Case",
              "exits": [{
                "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
                "name": "test exit"
              }]
            }]
          }]}))
  end

  test "validate Core.Log config" do
    # Message field required but missing.
    {:error, _} = FlowRunner.compile(~s({"specification_version": "1.0.0-rc1",
          "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
          "flows":[{
            "uuid":"3666a05d-3792-482b-8f7f-9e2472e4f027",
            "blocks":[{
              "uuid":"3666a05d-3792-482b-8f7f-9e2472e4f027",
              "type": "Core.Log"
            }]
          }]}))
    {:ok, _} = FlowRunner.compile(~s({"specification_version": "1.0.0-rc1",
          "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
          "flows":[{
            "uuid":"3666a05d-3792-482b-8f7f-9e2472e4f027",
            "blocks":[{
              "uuid":"3666a05d-3792-482b-8f7f-9e2472e4f027",
              "type": "Core.Log",
              "config": {"message": "hello"}
            }]
          }]}))
  end

  test "unknown block type" do
    # Block type is not handled by us.
    {:error, _} = FlowRunner.compile(~s({"specification_version": "1.0.0-rc1",
          "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
          "flows":[{
            "uuid":"3666a05d-3792-482b-8f7f-9e2472e4f027",
            "blocks":[{
              "uuid":"3666a05d-3792-482b-8f7f-9e2472e4f027",
              "type": "Nonexistant type"
            }]
          }]}))
  end

  test "message is missing prompt uuid" do
    {:error, _} = FlowRunner.compile(~s({"specification_version": "1.0.0-rc1",
          "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
          "flows":[{
            "uuid":"3666a05d-3792-482b-8f7f-9e2472e4f027",
            "blocks":[{
              "uuid":"3666a05d-3792-482b-8f7f-9e2472e4f027",
              "type": "MobilePrimitives.Message"
            }]
          }]}))
    # UUID is invalid
    {:error, _} = FlowRunner.compile(~s({"specification_version": "1.0.0-rc1",
          "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
          "flows":[{
            "uuid":"3666a05d-3792-482b-8f7f-9e2472e4f027",
            "blocks":[{
              "uuid":"3666a05d-3792-482b-8f7f-9e2472e4f027",
              "type": "MobilePrimitives.Message",
              "config": {"prompt": "not a uuid"}
            }]
          }]}))
    {:ok, _} = FlowRunner.compile(~s({"specification_version": "1.0.0-rc1",
          "uuid": "3666a05d-3792-482b-8f7f-9e2472e4f027",
          "flows":[{
            "uuid":"3666a05d-3792-482b-8f7f-9e2472e4f027",
            "blocks":[{
              "uuid":"3666a05d-3792-482b-8f7f-9e2472e4f027",
              "type": "MobilePrimitives.Message",
              "config": {"prompt": "3666a05d-3792-482b-8f7f-9e2472e4f027"}
            }]
          }]}))
  end
end
