defmodule FlowRunner.CustomBlocks.DynamicSelectOneResponseTest do
  use ExUnit.Case, async: true

  alias FlowRunner.Context
  alias FlowRunner.CustomBlocks.DynamicSelectOneResponse
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow
  alias FlowRunner.Spec.Language
  alias FlowRunner.Spec.Resource
  alias FlowRunner.Spec.ResourceValue

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
      resources: [
        resource("prompt-alpha", "Alpha label"),
        resource("prompt-bravo", "Bravo label")
      ]
    }

    {container, flow, block, %Context{language: "eng", mode: "TEXT"}}
  end

  @spec setup_incoming_block(choice_expression :: String.t(), vars :: map) ::
          {Container.t(), Flow.t(), Block.t(), Context.t()}
  defp setup_incoming_block(choice_expression, vars) do
    block = %Block{
      uuid: "dynamic-block",
      type: "Io.Turn.DynamicSelectOneResponse",
      config: %{choice_expression: choice_expression, destination_block: "destination-block"},
      exits: []
    }

    flow = %Flow{
      uuid: "flow",
      languages: [%Language{id: @language_id, iso_639_3: "eng"}],
      blocks: [block]
    }

    container = %Container{flows: [flow], resources: []}

    {container, flow, block, %Context{language: "eng", mode: "TEXT", vars: vars}}
  end

  describe "evaluate_incoming/4" do
    test "offers a choice for each [value, label] pair and waits for the reply" do
      {container, flow, block, context} =
        setup_incoming_block(~S|map(options, &[&1, concatenate(&1, " label")])|, %{
          "options" => ["Alpha", "Bravo"]
        })

      assert {:ok,
              %Container{
                resources: [
                  %Resource{values: [%ResourceValue{value: "Alpha label"}]},
                  %Resource{values: [%ResourceValue{value: "Bravo label"}]}
                ]
              }, _flow, %Block{config: %{choices: [%{name: "Alpha"}, %{name: "Bravo"}]}},
              %Context{waiting_for_user_input: true}} =
               DynamicSelectOneResponse.evaluate_incoming(container, flow, block, context)
    end

    test "returns an error when the list the options are built from is missing" do
      {container, flow, block, context} = setup_incoming_block("map(options, &[&1, &1])", %{})

      assert {:error,
              ~S|expected a list of [value, label] pairs from "map(options, &[&1, &1])", got: %{"__type__" => "expression/v1error", "__value__" => nil, "error" => true, "message" => "Invalid enumerable"}|} =
               DynamicSelectOneResponse.evaluate_incoming(container, flow, block, context)
    end

    test "returns an error when an option is not a [value, label] pair" do
      {container, flow, block, context} =
        setup_incoming_block("options", %{"options" => ["Alpha", "Bravo"]})

      assert {:error,
              ~S|expected a list of [value, label] pairs from "options", got: ["Alpha", "Bravo"]|} =
               DynamicSelectOneResponse.evaluate_incoming(container, flow, block, context)
    end
  end

  describe "evaluate_outgoing/5" do
    # The picker journey routes by the selected position, so the response must
    # carry the chosen choice's index (parity with the static SelectOneResponse).
    test "returns the index of the selected choice" do
      {container, flow, block, context} = setup_block()

      assert {:ok, %{"name" => "Bravo", "index" => 1, "label" => "Bravo label"}} =
               DynamicSelectOneResponse.evaluate_outgoing(
                 container,
                 flow,
                 block,
                 context,
                 "Bravo"
               )

      assert {:ok, %{"name" => "Alpha", "index" => 0, "label" => "Alpha label"}} =
               DynamicSelectOneResponse.evaluate_outgoing(
                 container,
                 flow,
                 block,
                 context,
                 "Alpha"
               )
    end

    test "is invalid when no choice test matches the response" do
      {container, flow, block, context} = setup_block()

      assert {:invalid, _reason} =
               DynamicSelectOneResponse.evaluate_outgoing(container, flow, block, context, "Zulu")
    end
  end
end
