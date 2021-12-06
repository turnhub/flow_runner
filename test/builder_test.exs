defmodule FlowRunner.FlowBuilderTest do
  use ExUnit.Case
  doctest FlowRunner.FlowBuilder

  test "as_floip" do
    one_minute = :timer.minutes(1)

    assert %{
             "specification_version" => "1.0.0-rc3",
             "name" => "My flow",
             "description" => "The description",
             "uuid" => _container_uuid,
             "flows" => [
               %{
                 "name" => "first_flow",
                 "uuid" => _flow_uuid,
                 "first_block_id" => first_block_uuid,
                 "interaction_timeout" => ^one_minute,
                 "languages" => languages,
                 "blocks" => [
                   %{
                     "config" => %{
                       "choices" => [
                         %{
                           "name" => "reply_1",
                           "prompt" => reply_1_choice_prompt,
                           "test" => "block.response = \"reply_1\""
                         },
                         %{
                           "name" => "reply_2",
                           "prompt" => reply_2_choice_prompt,
                           "test" => "block.response = \"reply_2\""
                         }
                       ],
                       "prompt" => first_flow_prompt
                     },
                     "exits" => [
                       %{
                         "destination_block" => reply_1_uuid,
                         "name" => "reply_1_exit",
                         "test" => "block.value = \"reply_1\"",
                         "uuid" => _reply_1_exit_uuid
                       },
                       %{
                         "destination_block" => reply_2_uuid,
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
                     "config" => %{"prompt" => reply_1_prompt_uuid},
                     "exits" => [],
                     "label" => "this is reply 1",
                     "name" => "reply_1",
                     "type" => "MobilePrimitives.Message",
                     "uuid" => reply_1_uuid
                   },
                   %{
                     "config" => %{"prompt" => reply_2_prompt_uuid},
                     "exits" => [],
                     "label" => "this is reply 2",
                     "name" => "reply_2",
                     "type" => "MobilePrimitives.Message",
                     "uuid" => reply_2_uuid
                   }
                 ]
               }
             ],
             "resources" => resources
           } = FlowRunner.Builder.Floip1.as_floip()

    assert [english, afrikaans] = languages

    # helper function to find the resource value for a resource uuid and language code
    resource_value = fn resource_uuid, language_code ->
      resource = Enum.find(resources, &(&1["uuid"] == resource_uuid))
      language = Enum.find(languages, &(&1["iso_639_3"] == language_code))

      resource_value =
        Enum.find(resource["values"], fn resource_value ->
          resource_value["language_id"] == language["id"]
        end)

      resource_value["value"]
    end

    assert english["iso_639_3"] == "eng"
    assert english["label"] == "English"

    assert "Hello world" == resource_value.(first_flow_prompt, "eng")
    assert "Send me reply 1" == resource_value.(reply_1_choice_prompt, "eng")
    assert "Send me reply 2" == resource_value.(reply_2_choice_prompt, "eng")
    assert "This is reply 1" == resource_value.(reply_1_prompt_uuid, "eng")
    assert "This is reply 2" == resource_value.(reply_2_prompt_uuid, "eng")

    assert afrikaans["iso_639_3"] == "afr"
    assert afrikaans["label"] == "Afrikaans"

    assert "Hello Wêreld" == resource_value.(first_flow_prompt, "afr")
    assert "Stuur vir my antwoord 1" == resource_value.(reply_1_choice_prompt, "afr")
    assert "Stuur vir my antwoord 2" == resource_value.(reply_2_choice_prompt, "afr")
    assert "Dit is antwoord 1" == resource_value.(reply_1_prompt_uuid, "afr")
    assert "Dit is antwoord 2" == resource_value.(reply_2_prompt_uuid, "afr")
  end
end
