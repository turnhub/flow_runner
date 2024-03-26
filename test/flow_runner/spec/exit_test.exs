defmodule FlowRunner.Spec.ExitTest do
  use ExUnit.Case
  alias FlowRunner.Spec.Exit

  test "Exit matching a string containing a numeric value" do
    assert Exit.evaluate(
             %Exit{
               uuid: "dd605033-ef05-4edd-9170-1adb1a8c45a5",
               name: "Exit for Text_cf8c95",
               destination_block: "37ce2c90-f5f7-5772-8464-b2a1553a78b8",
               semantic_label: nil,
               test: "ref_Buttons_7bef16 == \"2\"",
               default: false,
               config: %{},
               vendor_metadata: %{}
             },
             %{vars: %{"ref_Buttons_7bef16" => "2"}}
           )
  end

  test "Exit matching a string containing a boolean-ish value" do
    assert Exit.evaluate(
             %Exit{
               uuid: "dff8ba17-d73d-4607-91de-dca8b2ed8630",
               name: "Exit for Text_4dd50b",
               destination_block: "be115dce-1f85-515c-9494-95bf3f00e87d",
               semantic_label: nil,
               test: "ref_Buttons_7bef16 == \"True\"",
               default: false,
               config: %{},
               vendor_metadata: %{}
             },
             %{
               vars: %{
                 "ref_Buttons_7bef16" => %{
                   "__value__" => "True",
                   "index" => 0,
                   "label" => "True",
                   "name" => "True"
                 }
               }
             }
           )
  end
end
