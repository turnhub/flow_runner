defmodule FlowRunner.FlowBuilderTest do
  defmodule Floip1 do
    @moduledoc """
    A module to make it easier to create flows without needing
    to write the JSON manually
    """
    use FlowRunner.FlowBuilder

    default_language("eng")

    flow :first_flow do
      block :prompt do
        prompt("Hello world",
          reply_1: "Send me reply 1",
          reply_2: "Send me reply 2"
        )
      end

      block(:reply_1, do: text("This is reply 1"))

      block(:reply_2, do: text("This is reply 2"))
    end
  end

  use ExUnit.Case
  doctest FlowRunner.FlowBuilder

  test "as_floip" do
    assert %{
             "flows" => [
               %{
                 "name" => "first_flow",
                 "uuid" => _flow_uuid,
                 "first_block_id" => first_block_uuid,
                 "interaction_timeout" => 300_000,
                 "languages" => [],
                 "blocks" => [
                   %{
                     "config" => %{
                       "choices" => [
                         %{
                           "name" => "reply_1",
                           "prompt" => "???",
                           "test" => "block.response = \"reply_1\""
                         },
                         %{
                           "name" => "reply_2",
                           "prompt" => "???",
                           "test" => "block.response = \"reply_2\""
                         }
                       ],
                       "prompt" => "???"
                     },
                     "exits" => [
                       %{
                         "destination_block" => "???",
                         "name" => "reply_1_exit",
                         "test" => "block.value = \"reply_1\"",
                         "uuid" => _reply_1_exit_uuid
                       },
                       %{
                         "destination_block" => "???",
                         "name" => "reply_2_exit",
                         "test" => "block.value = \"reply_2\"",
                         "uuid" => _reply_2_exit_uuid
                       }
                     ],
                     "label" => "hello world",
                     "name" => "prompt",
                     "type" => "MobilePrimitives.SelectOneResponse",
                     "uuid" => first_block_uuid
                   },
                   %{
                     "config" => %{"prompt" => "???"},
                     "exits" => [],
                     "label" => "this is reply 1",
                     "name" => "reply_1",
                     "type" => "MobilePrimitives.Message",
                     "uuid" => _reply_1_uuid
                   },
                   %{
                     "config" => %{"prompt" => "???"},
                     "exits" => [],
                     "label" => "this is reply 2",
                     "name" => "reply_2",
                     "type" => "MobilePrimitives.Message",
                     "uuid" => _reply_2_uuid
                   }
                 ]
               }
             ],
             "resources" => [],
             "specification_version" => "1.0.0-rc3",
             "uuid" => _second_uuid
           } = Floip1.as_floip()
  end
end
