defmodule BlockTest do
  use ExUnit.Case
  doctest FlowRunner.Spec.Block

  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Exit
  alias FlowRunner.Spec.Flow

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

  test "fetch default block" do
    # 1. With NO default exit
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

    assert {:error, "No default exit available"} =
             Block.fetch_default_block(block, %Flow{}, context)

    # 2. With default exit
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

    assert {:ok, %Context{}, _no_destination_block = nil} =
             Block.fetch_default_block(block, %Flow{}, context)
  end

  test "fetch next block" do
    # 1. With NO default exit
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

    assert {:error, "No default exit available"} = Block.fetch_next_block(block, %Flow{}, context)

    # 2. With default exit
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

    assert {:ok, %Context{}, _no_destination_block = nil} =
             Block.fetch_next_block(block, %Flow{}, context)
  end

  test "evaluate exits with complex values containing __value__" do
    # When an expression returns a map with __value__ (like has_phone),
    # the exit should extract and use the __value__ for boolean evaluation
    context = %Context{
      vars: %{
        "valid" => %{"__value__" => true, "phonenumber" => "+27820001001"}
      }
    }

    block = %Block{
      exits: [
        %Exit{
          uuid: "success-exit",
          test: "valid"
        },
        %Exit{
          uuid: "failure-exit",
          default: true
        }
      ]
    }

    # Should match the first exit because valid.__value__ is true
    assert {:ok, %Exit{uuid: "success-exit"}} = Block.evaluate_exits(block, context)

    # Test with __value__ = false
    context_false = %Context{
      vars: %{
        "valid" => %{"__value__" => false, "phonenumber" => nil}
      }
    }

    # Should fall through to default exit because valid.__value__ is false
    assert {:ok, %Exit{uuid: "failure-exit"}} = Block.evaluate_exits(block, context_false)
  end
end
