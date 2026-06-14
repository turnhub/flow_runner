defmodule FlowRunner.CustomBlocks.DynamicSelectOneResponseTest do
  use ExUnit.Case, async: true

  alias FlowRunner.Context
  alias FlowRunner.CustomBlocks.DynamicSelectOneResponse
  alias FlowRunner.Spec.{Block, Container, Flow, Language, Resource, ResourceValue}

  @language_id "11111111-1111-1111-1111-111111111111"

  defp resource(uuid, value) do
    %Resource{
      uuid: uuid,
      values: [
        %ResourceValue{
          language_id: @language_id,
          content_type: "TEXT",
          mime_type: "text/plain",
          modes: ["TEXT"],
          value: value
        }
      ]
    }
  end

  defp setup_block do
    choices = [
      %{name: "Alpha", test: ~S(block.response = "Alpha"), prompt: "prompt-alpha"},
      %{name: "Bravo", test: ~S(block.response = "Bravo"), prompt: "prompt-bravo"}
    ]

    block = %Block{type: "Io.Turn.DynamicSelectOneResponse", config: %{choices: choices}}
    flow = %Flow{languages: [%Language{id: @language_id, iso_639_3: "eng"}]}

    container = %Container{
      resources: [resource("prompt-alpha", "Alpha label"), resource("prompt-bravo", "Bravo label")]
    }

    {container, flow, block, %Context{language: "eng", mode: "TEXT"}}
  end

  describe "evaluate_outgoing/5" do
    # The picker journey routes by the selected position, so the response must
    # carry the chosen choice's index (parity with the static SelectOneResponse).
    test "returns the index of the selected choice" do
      {container, flow, block, context} = setup_block()

      assert {:ok, %{"name" => "Bravo", "index" => 1, "label" => "Bravo label"}} =
               DynamicSelectOneResponse.evaluate_outgoing(container, flow, block, context, "Bravo")

      assert {:ok, %{"name" => "Alpha", "index" => 0, "label" => "Alpha label"}} =
               DynamicSelectOneResponse.evaluate_outgoing(container, flow, block, context, "Alpha")
    end

    test "is invalid when no choice test matches the response" do
      {container, flow, block, context} = setup_block()

      assert {:invalid, _reason} =
               DynamicSelectOneResponse.evaluate_outgoing(container, flow, block, context, "Zulu")
    end
  end
end
