defmodule ResourceTest do
  use ExUnit.Case

  alias FlowRunner.Spec.Flow
  alias FlowRunner.Spec.Resource
  alias FlowRunner.Spec.ResourceValue

  @flow %Flow{
    languages: [
      %{"id" => "22", "iso_639_3" => "eng", "label" => "English"},
      %{"id" => "23", "iso_639_3" => "fra", "label" => "French"}
    ]
  }

  test "matching resource language check" do
    resource = %Resource{
      values: [
        %ResourceValue{
          language_id: "23",
          modes: ["USSD", "TEXT"],
          value: "french"
        },
        %ResourceValue{
          language_id: "25",
          modes: ["USSD", "TEXT"],
          value: "non-existent language"
        }
      ]
    }

    # no matching language
    assert {:error, _} = Resource.matching_resource(resource, "eng", "TEXT", @flow)

    # no matching mode.
    assert {:error, _} = Resource.matching_resource(resource, "fra", "RICH_MESSAGING", @flow)

    # matching language and mode
    assert {:ok, %ResourceValue{value: "french"}} =
             Resource.matching_resource(resource, "fra", "TEXT", @flow)
  end
end
