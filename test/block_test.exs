defmodule BlockTest do
  use ExUnit.Case
  doctest FlowRunner.Spec.Block

  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Exit

  test "evaluate user input" do
    {:ok, context} =
      Block.evaluate_user_input(
        %Block{name: "customers_age"},
        %Context{waiting_for_user_input: true},
        "20"
      )

    assert %Context{
             vars: %{
               "block" => %{"value" => "20"},
               "customers_age" => "20"
             },
             waiting_for_user_input: false
           } == context
  end

  test "evaluate exits" do
    context = %Context{
      vars: %{"block" => %{"value" => 10}}
    }

    block = %Block{
      exits: [
        %Exit{
          uuid: "b586afa7-0097-4805-9951-f6d3156c08db",
          test: "block.value = 5"
        }
      ]
    }

    # No default, no truthy exits
    assert {:error, _} = Block.evaluate_exits(block, context)

    block = %Block{
      exits: [
        %Exit{
          uuid: "8718f313-3b40-4d92-87c7-e21b8a51c813",
          test: "block.value = 5"
        },
        %Exit{
          uuid: "b586afa7-0097-4805-9951-f6d3156c08db",
          test: "block.value = 10"
        }
      ]
    }

    # The one block evaluates to true and is selected even though
    # the default exit block is defined first in the list of exits
    assert {:ok, %Exit{uuid: "b586afa7-0097-4805-9951-f6d3156c08db"}} =
             Block.evaluate_exits(block, context)

    block = %Block{
      exits: [
        %Exit{
          uuid: "cbf4382f-0ce0-426b-9a3c-40cbe84dd081",
          default: true
        },
        %Exit{
          uuid: "b586afa7-0097-4805-9951-f6d3156c08db",
          test: "block.value = 5"
        }
      ]
    }

    # Default evaluates to true.
    assert {:ok, %Exit{uuid: "cbf4382f-0ce0-426b-9a3c-40cbe84dd081"}} =
             Block.evaluate_exits(block, context)

    block = %Block{
      exits: [
        %Exit{
          uuid: "b586afa7-0097-4805-9951-f6d3156c08db",
          test: "block.value = 10"
        },
        %Exit{
          uuid: "cbf4382f-0ce0-426b-9a3c-40cbe84dd081",
          default: true
        }
      ]
    }

    # Default ignored since block results in true.
    assert {:ok, %Exit{uuid: "b586afa7-0097-4805-9951-f6d3156c08db"}} =
             Block.evaluate_exits(block, context)
  end
end
