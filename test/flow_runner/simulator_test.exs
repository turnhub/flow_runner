defmodule FlowRunner.SimulatorTest do
  use ExUnit.Case, async: true
  alias FlowRunner.Simulator

  @spec read_floip!(name :: String.t()) :: FlowRunner.Spec.Container.t()
  defp read_floip!(name) do
    "priv/fixtures/test/simulator/#{name}.flow"
    |> File.read!()
    |> Jason.decode!()
    |> FlowRunner.compile!()
  end

  defp with_content_type(resource_value_outputs, content_type) do
    resource_value_outputs
    |> Enum.filter(&(&1.content_type == content_type))
  end

  defp has_value(resource_value_outputs, value) do
    Enum.any?(resource_value_outputs, &(&1.value =~ value)) ||
      flunk("Did not find #{inspect(value)} in #{inspect(resource_value_outputs)}")
  end

  defp has_values(resource_value_outputs, values) do
    values
    |> Enum.reduce(resource_value_outputs, fn value, resource_values_outputs ->
      Enum.reject(resource_values_outputs, &(&1.value =~ value))
    end)
    |> Enum.empty?() || flunk("#{inspect(values)} not all in #{inspect(resource_value_outputs)}")
  end

  test "simulator with escaped lines" do
    sim = Simulator.new(read_floip!("simulator_with_escaped_lines"))

    {:end, _sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> hd()
           |> Map.get(:value) == "No"
  end

  test "simulator with escaped new lines" do
    sim = Simulator.new(read_floip!("simulator_with_escaped_new_lines"))
    {:waiting, sim, _outputs} = Simulator.start(sim)
    {:waiting, sim, _outputs} = Simulator.next(sim, "1")
    {:end, _sim, _outputs} = Simulator.next(sim, "2")
  end

  test "simulator with infinite recursion" do
    assert {:error, sim, "Exceeded max recursion calls allowed (1000)"} =
             "infinite_recursion" |> read_floip!() |> Simulator.new() |> Simulator.start()

    assert sim.context.last_block_uuid
  end

  test "simulator with log output" do
    sim = Simulator.new(read_floip!("simulator_with_log_output"))
    {:end, _sim, outputs} = Simulator.start(sim)

    date = Date.utc_today()

    assert outputs
           |> get_in([:log, :text])
           |> Enum.map(& &1.value) ==
             ["hello #{date}"]
  end

  test "simulator with boolean" do
    sim = Simulator.new(read_floip!("simulator_with_boolean"))
    {:end, _sim, outputs} = Simulator.start(sim)

    assert outputs == []
  end

  test "simulator with whatsapp flow" do
    sim = Simulator.new(read_floip!("whatsapp_send_flow"))
    {:waiting, _sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value(
             ~s(Flow with ID "1289489102445874" is sent to the phone using "click!" as the call to action.)
           )

    # Assert payload is rendered
    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value(~s(Payload: %{"foo" => "bar"}))
  end

  test "simulator with whatsapp flow without payload" do
    sim = Simulator.new(read_floip!("whatsapp_send_flow_no_payload"))
    {:waiting, _sim, outputs} = Simulator.start(sim)

    text_output =
      outputs
      |> get_in([:message, :text])
      |> with_content_type("TEXT")
      |> List.first()

    # Assert basic flow info is present
    assert text_output.value =~ "Flow with ID \"9876543210\""
    assert text_output.value =~ "using \"Open Flow\" as the call to action"

    # Assert payload is NOT present in output
    refute text_output.value =~ "Payload:"
  end

  test "simulator with whatsapp request location" do
    sim = Simulator.new(read_floip!("whatsapp_request_location_basic"))
    {:waiting, _sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("Please share your location so we can help you better.")

    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("Send location")
  end

  test "simulator with quick reply" do
    sim = Simulator.new(read_floip!("quick_reply_stack"))

    {:waiting, sim, _outputs} = Simulator.start(sim)
    {:waiting, sim, outputs} = Simulator.next(sim, "1")

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("1 for 1")

    assert sim.block.name == "destination_case_condition_0"
    {:end, _sim, _outputs} = Simulator.next(sim, "bar")

    sim = Simulator.new(read_floip!("quick_reply_stack"))
    {:waiting, sim, _outputs} = Simulator.start(sim)
    {:end, sim, _outputs} = Simulator.next(sim, "2")
    assert sim.block.name == "destination_case_condition_1_text"

    assert %{
             "io" => %{
               "turn" => %{
                 "stacks_dsl" => %{
                   "0.1.0" => %{
                     "card" => %{
                       "condition" => "d == \"2\"",
                       "meta" => %{"line" => 20},
                       "name" => "Destination",
                       "uuid" => _uuid
                     },
                     "card_item" => %{
                       "meta" => %{"line" => 21},
                       "type" => "text"
                     },
                     "index" => 1
                   }
                 }
               }
             }
           } = sim.block.vendor_metadata
  end

  test "simulator with lists" do
    sim = Simulator.new(read_floip!("list_stack"))
    {:waiting, sim, outputs} = Simulator.start(sim)

    # check the buttons have the correct
    assert outputs
           |> get_in([:interactive, :list])
           |> Enum.map(& &1.event_value) ==
             ["Button One", "Button Two", "Button Three", "Button Four", "Button Five"]

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("click a button")

    assert outputs
           |> get_in([:interactive, :list_call_to_action])
           |> with_content_type("TEXT")
           |> has_values(["Call to Action"])

    assert outputs
           |> get_in([:interactive, :list])
           |> with_content_type("TEXT")
           |> has_values([
             "Button One",
             "Button Two",
             "Button Three",
             "Button Four",
             "Button Five"
           ])

    {:end, sim, _outputs} = Simulator.next(sim, "one")
    assert sim.block.name == "destination_case_condition_0_text"

    sim = Simulator.new(read_floip!("list_stack"))
    {:waiting, sim, _outputs} = Simulator.start(sim)
    {:end, sim, _outputs} = Simulator.next(sim, "two")
    assert sim.block.name == "destination_case_condition_1_text"
  end

  test "simulator with ask and video" do
    sim = Simulator.new(read_floip!("simulator_with_ask_and_video"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("What's your name?")

    assert outputs
           |> get_in([:message, :video])
           |> with_content_type("VIDEO")
           |> has_value("https://example.org/video.mp4")

    {:end, sim, outputs} = Simulator.next(sim, "santiago")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("hi santiago")

    assert sim.block.name == "greetings_text"
  end

  test "simulator with ask" do
    sim = Simulator.new(read_floip!("simulator_with_ask"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("Please enter some text")

    {:end, _sim, outputs} = Simulator.next(sim, "hey")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("the end - c equals 2")
  end

  test "simulator with ask with no assignment" do
    sim = Simulator.new(read_floip!("simulator_with_ask_with_no_assignment"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("What is 1 * 1 ?")

    {:waiting, sim, outputs} = Simulator.next(sim, "1")

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("That is correct!")

    assert sim.block.name == "answer_case_condition_0"
  end

  test "simulator with buttons and document" do
    sim = Simulator.new(read_floip!("simulator_with_buttons_and_document"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("Please read carefully")

    assert outputs
           |> get_in([:interactive, :document])
           |> with_content_type("TEXT")
           |> has_value("https://example.org/document.pdf")

    assert outputs
           |> get_in([:interactive, :footer])
           |> with_content_type("TEXT")
           |> has_value("this is the footer")

    assert sim.block.name == "read_document"

    {:end, sim, outputs} = Simulator.next(sim, "End")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("Thanks!")

    assert sim.block.name == "end_text"
  end

  test "simulator with buttons with labels" do
    sim = Simulator.new(read_floip!("simulator_with_buttons_with_labels"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("Continue")

    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("Finish")

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("this is the body")

    assert outputs
           |> get_in([:interactive, :footer])
           |> with_content_type("TEXT")
           |> has_value("this is the footer")

    assert sim.block.name == "read"

    {:end, sim, outputs} = Simulator.next(sim, "Finish")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("Thanks!")

    assert sim.block.name == "end_text"
  end

  test "simulator with buttons and routing" do
    sim = Simulator.new(read_floip!("simulator_with_buttons_and_routing"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("Continue")

    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("Finish")

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("this is the body")

    assert outputs
           |> get_in([:interactive, :footer])
           |> with_content_type("TEXT")
           |> has_value("this is the footer")

    assert sim.block.name == "option"

    {:end, sim, outputs} = Simulator.next(sim, "Finish")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("Thanks!")

    assert sim.block.name == "finish_text"
  end

  test "simulator with buttons with labels and routing" do
    sim = Simulator.new(read_floip!("simulator_with_buttons_with_labels_and_routing"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("Continue")

    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("Finish")

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("this is the body")

    assert outputs
           |> get_in([:interactive, :footer])
           |> with_content_type("TEXT")
           |> has_value("this is the footer")

    assert sim.block.name == "option"

    {:end, sim, outputs} = Simulator.next(sim, "Finish")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("Thanks!")

    assert sim.block.name == "end_text"
  end

  test "simulator with buttons and routing but no card reference" do
    sim = Simulator.new(read_floip!("simulator_with_buttons_and_routing_but_not_card_reference"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("Continue")

    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("Finish")

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("this is the body")

    assert outputs
           |> get_in([:interactive, :footer])
           |> with_content_type("TEXT")
           |> has_value("this is the footer")

    assert sim.block.name == "option"

    {:end, sim, outputs} = Simulator.next(sim, "Continue")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("Let's go!")

    assert sim.block.name == "next_text"
  end

  test "simular with mandatory default exit" do
    sim = Simulator.new(read_floip!("simulator_with_mandatory_default_exit"))

    sim =
      Simulator.update_context(sim, %{
        "contact" => %{
          "var" => "3"
        }
      })

    {:end, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:log, :text])
           |> with_content_type("TEXT")
           |> has_value("Card \"Card\" is missing a default exit.")

    assert sim.block.name == "card_case_condition_2_log"
  end

  test "simulator with buttons and routing but no card reference and fallback condition" do
    sim =
      Simulator.new(
        read_floip!(
          "simulator_with_buttons_and_routing_but_no_card_references_and_fallback_condition"
        )
      )

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("Continue")

    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("Finish")

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("this is the body")

    assert outputs
           |> get_in([:interactive, :footer])
           |> with_content_type("TEXT")
           |> has_value("this is the footer")

    assert sim.block.name == "option"

    {:end, sim, outputs} = Simulator.next(sim, "None")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("Thanks!")

    assert sim.block.name == "end_text"
  end

  test "simulator with buttons and routing without condition" do
    sim = Simulator.new(read_floip!("simulator_with_buttons_and_routing_without_condition"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("Continue")

    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("Finish")

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("this is the body")

    assert outputs
           |> get_in([:interactive, :footer])
           |> with_content_type("TEXT")
           |> has_value("this is the footer")

    assert sim.block.name == "option"

    {:end, sim, outputs} = Simulator.next(sim, "None")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("Thanks!")

    assert sim.block.name == "end_text"
  end

  test "simulator with buttons with no assignment" do
    sim = Simulator.new(read_floip!("simulator_with_buttons_with_no_assignment"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("Morning")

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("_When would practicing stress management skills help you the most?_")

    assert sim.block.name == "time"

    {:end, sim, outputs} = Simulator.next(sim, "Morning")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("activity card")

    assert sim.block.name == "activity_text"
  end

  test "simulator with time formatted options" do
    sim = Simulator.new(read_floip!("simulator_with_dynamic_list_time_formatted_options"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:interactive, :list])
           |> with_content_type("TEXT")
           |> has_value("11:00:00")

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("Pick an option!")

    assert sim.block.name == "option_picked"

    {:end, _sim, _outputs} = Simulator.next(sim, "11:00:00")
  end

  @tag :current
  test "simulator with dynamic buttons" do
    sim = Simulator.new(read_floip!("simulator_with_dynamic_buttons"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("click a button")

    assert sim.block.name == "d"

    {:waiting, sim, outputs} = Simulator.next(sim, "one")

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("you clicked one")

    assert sim.block.name == "destination"
  end

  test "simulator with list and routing" do
    sim = Simulator.new(read_floip!("simulator_with_list_and_routing"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("Please choose carefully")

    assert outputs
           |> get_in([:interactive, :header])
           |> with_content_type("TEXT")
           |> has_value("this is the header")

    assert outputs
           |> get_in([:interactive, :footer])
           |> with_content_type("TEXT")
           |> has_value("this is the footer")

    assert sim.block.name == "option"

    {:end, sim, outputs} = Simulator.next(sim, "End")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("Thanks!")

    assert sim.block.name == "end_text"
  end

  test "simulator with list with labels and routing" do
    sim = Simulator.new(read_floip!("simulator_with_list_with_labels_and_routing"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("Please choose carefully")

    assert outputs
           |> get_in([:interactive, :header])
           |> with_content_type("TEXT")
           |> has_value("this is the header")

    assert outputs
           |> get_in([:interactive, :footer])
           |> with_content_type("TEXT")
           |> has_value("this is the footer")

    assert sim.block.name == "option"

    {:end, sim, outputs} = Simulator.next(sim, "Finish")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("Thanks!")

    assert sim.block.name == "end_text"
  end

  test "simulator with list and routing but no card reference" do
    sim = Simulator.new(read_floip!("simulator_with_list_and_routing_but_no_card_references"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("Please choose carefully")

    assert outputs
           |> get_in([:interactive, :header])
           |> with_content_type("TEXT")
           |> has_value("this is the header")

    assert outputs
           |> get_in([:interactive, :footer])
           |> with_content_type("TEXT")
           |> has_value("this is the footer")

    assert sim.block.name == "option"

    {:end, sim, outputs} = Simulator.next(sim, "End")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("Thanks!")

    assert sim.block.name == "end_text"
  end

  test "simulator with list, header and footer" do
    sim = Simulator.new(read_floip!("simulator_with_list_header_and_footer"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("Please choose carefully")

    assert outputs
           |> get_in([:interactive, :header])
           |> with_content_type("TEXT")
           |> has_value("this is the header")

    assert outputs
           |> get_in([:interactive, :footer])
           |> with_content_type("TEXT")
           |> has_value("this is the footer")

    assert sim.block.name == "choose"

    {:end, sim, outputs} = Simulator.next(sim, "End")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("Thanks!")

    assert sim.block.name == "end_text"
  end

  test "whatsapp template message with buttons" do
    sim = Simulator.new(read_floip!("whatsapp_template_message"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("[DEBUG]\nTemplate template_name sent with language eng.")

    assert outputs
           |> get_in([:message, :button])
           |> with_content_type("TEXT")
           |> has_value("card1")

    assert outputs
           |> get_in([:message, :button])
           |> with_content_type("TEXT")
           |> has_value("card2")

    {:end, _sim, outputs} = Simulator.next(sim, "card1")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("This is card 1")
  end

  test "whatsapp template message with body params with translations using default language" do
    sim = Simulator.new(read_floip!("whatsapp_template_message_with_translations"))

    {:end, _sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("Body parameters: [Jane, My Journey]")
  end

  test "whatsapp template message with body params using translations" do
    sim = Simulator.new(read_floip!("whatsapp_template_message_with_translations"))

    {:end, _sim, outputs} = Simulator.start(sim, %{}, "bel")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("Body parameters: [Мінае, завуч, Мінае]")
  end

  test "whatsapp template message with header params with translations using default language" do
    sim = Simulator.new(read_floip!("whatsapp_template_message_with_header_translation"))

    {:end, _sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("Header parameters: [John]")
  end

  test "whatsapp template message with header params with translations using translation" do
    sim = Simulator.new(read_floip!("whatsapp_template_message_with_header_translation"))

    {:end, _sim, outputs} = Simulator.start(sim, %{}, "por_BR")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("Header parameters: [João]")
  end

  test "whatsapp template message with buttons not matching user input" do
    sim = Simulator.new(read_floip!("whatsapp_template_message"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("[DEBUG]\nTemplate template_name sent with language eng.")

    assert outputs
           |> get_in([:message, :button])
           |> with_content_type("TEXT")
           |> has_value("card1")

    assert outputs
           |> get_in([:message, :button])
           |> with_content_type("TEXT")
           |> has_value("card2")

    {:end, _sim, outputs} = Simulator.next(sim, "None")

    assert outputs == []
  end

  test "whatsapp template message with buttons not matching user input with numeric messages" do
    sim = Simulator.new(read_floip!("whatsapp_template_message"))

    {:waiting, sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("[DEBUG]\nTemplate template_name sent with language eng.")

    assert outputs
           |> get_in([:message, :button])
           |> with_content_type("TEXT")
           |> has_value("card1")

    assert outputs
           |> get_in([:message, :button])
           |> with_content_type("TEXT")
           |> has_value("card2")

    {:end, _sim, outputs} = Simulator.next(sim, "0")

    assert outputs == []
  end

  test "whatsapp template message with variable language in buttons" do
    sim = Simulator.new(read_floip!("whatsapp_template_message_with_variable_language"))

    {:waiting, sim, outputs} = Simulator.start(sim, %{"fields" => %{"language" => "eng"}})

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("[DEBUG]\nTemplate template_name sent with language eng.")

    assert outputs
           |> get_in([:message, :button])
           |> with_content_type("TEXT")
           |> has_value("card1")

    assert outputs
           |> get_in([:message, :button])
           |> with_content_type("TEXT")
           |> has_value("card2")

    {:end, _sim, outputs} = Simulator.next(sim, "card1")

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("This is card 1")
  end

  test "video" do
    sim = Simulator.new(read_floip!("simulator_video"))
    {:end, _sim, outputs} = Simulator.start(sim)

    assert outputs
           |> get_in([:message, :text])
           |> with_content_type("TEXT")
           |> has_value("video description")

    assert outputs
           |> get_in([:message, :video])
           |> with_content_type("VIDEO")
           |> has_value("https://example.org/video.mpg")
  end

  test "audio" do
    sim = Simulator.new(read_floip!("simulator_audio"))
    {:end, _sim, outputs} = Simulator.start(sim)

    [audio_message, text_message] = Keyword.get_values(outputs, :message)

    assert audio_message
           |> get_in([:audio])
           |> with_content_type("AUDIO")
           |> has_value("https://example.org/audio.mpg")

    assert text_message
           |> get_in([:text])
           |> with_content_type("TEXT")
           |> has_value("audio description")
  end

  test "document" do
    sim = Simulator.new(read_floip!("simulator_document"))
    {:end, _sim, outputs} = Simulator.start(sim)

    [document_message] = Keyword.get_values(outputs, :message)

    assert document_message
           |> get_in([:document])
           |> with_content_type("TEXT")
           |> has_value("https://example.org/document.pdf")

    assert document_message
           |> get_in([:text])
           |> with_content_type("TEXT")
           |> has_value("document description")
  end

  test "contact update" do
    sim = Simulator.new(read_floip!("simulator_contact_update"))
    assert {:end, sim, []} = Simulator.start(sim)
    assert sim.context.vars["contact"]["name"] == "Foo"
    assert sim.context.vars["contact"]["surname"] == "Bar"
    assert sim.context.vars["contact"]["language"] == "afr"
    assert sim.context.language == "afr"
  end

  test "natis" do
    sim = Simulator.new(read_floip!("simulator_natis"))
    assert {:waiting, sim, _outputs} = Simulator.start(sim)
    assert {:waiting, _sim, outputs} = Simulator.next(sim, "1")

    assert outputs == [
             message: [
               text: [
                 %Simulator.Output{
                   content_type: "TEXT",
                   mime_type: "text/plain",
                   raw_value: "You pressed the first button",
                   value: "You pressed the first button"
                 }
               ]
             ],
             interactive: [
               button: [
                 %Simulator.Output{
                   content_type: "TEXT",
                   mime_type: "text/plain",
                   raw_value: "1",
                   value: "1",
                   event_value: "1"
                 },
                 %Simulator.Output{
                   content_type: "TEXT",
                   mime_type: "text/plain",
                   raw_value: "2",
                   value: "2",
                   event_value: "2"
                 }
               ],
               image: [
                 %Simulator.Output{
                   content_type: "IMAGE",
                   mime_type: "application/octet-stream",
                   raw_value: "https://via.placeholder.com/800/F00/000",
                   value: "https://via.placeholder.com/800/F00/000"
                 }
               ],
               text: [
                 %Simulator.Output{
                   content_type: "TEXT",
                   mime_type: "text/plain",
                   raw_value: "Hello!",
                   value: "Hello!"
                 }
               ]
             ]
           ]
  end

  test "implicit stack with write_result" do
    sim = Simulator.new(read_floip!("simulator_implicit_stack_with_write_result"))

    assert {:waiting, sim, _outputs} = Simulator.start(sim)
    assert {:waiting, _sim, outputs} = Simulator.next(sim, "1")

    assert outputs == [
             message: [
               text: [
                 %Simulator.Output{
                   content_type: "TEXT",
                   mime_type: "text/plain",
                   raw_value: "You pressed the first button",
                   value: "You pressed the first button"
                 }
               ]
             ],
             interactive: [
               button: [
                 %Simulator.Output{
                   content_type: "TEXT",
                   mime_type: "text/plain",
                   raw_value: "1",
                   value: "1",
                   event_value: "1"
                 },
                 %Simulator.Output{
                   content_type: "TEXT",
                   mime_type: "text/plain",
                   raw_value: "2",
                   value: "2",
                   event_value: "2"
                 }
               ],
               text: [
                 %Simulator.Output{
                   content_type: "TEXT",
                   mime_type: "text/plain",
                   raw_value: "Hello!",
                   value: "Hello!"
                 }
               ],
               header: [
                 %Simulator.Output{
                   content_type: "TEXT",
                   mime_type: "text/plain",
                   raw_value: "this is the header",
                   value: "this is the header",
                   event_value: nil
                 }
               ],
               footer: [
                 %Simulator.Output{
                   content_type: "TEXT",
                   mime_type: "text/plain",
                   raw_value: "this is the footer",
                   value: "this is the footer",
                   event_value: nil
                 }
               ]
             ]
           ]
  end

  test "contact property enum field sanitization" do
    # Test enum value gets sanitized to structured object
    container = %{
      "name" => "Test Enum Sanitization",
      "description" => "Test description",
      "uuid" => "66980030-a035-42da-97de-64814acbd834",
      "resources" => [],
      "flows" => [
        %{
          "label" => nil,
          "name" => "test_flow",
          "blocks" => [
            %{
              "label" => nil,
              "name" => "test_enum_sanitization",
              "type" => "Core.SetContactProperty",
              "config" => %{
                "set_contact_property" => %{
                  "property_key" => "status",
                  "property_value" => "PENDING_APPROVAL"
                }
              },
              "tags" => [],
              "uuid" => "c180325c-c48c-5a18-a117-634366357b29",
              "ui_metadata" => %{
                "canvas_coordinates" => %{"x" => 0, "y" => 0}
              },
              "exits" => [
                %{
                  "default" => true,
                  "name" => "default_exit",
                  "config" => %{},
                  "test" => "",
                  "uuid" => "1318ac38-99ed-4f2f-b15f-5daf26ce3ece",
                  "semantic_label" => "",
                  "vendor_metadata" => %{},
                  "destination_block" => nil
                }
              ],
              "semantic_label" => nil,
              "vendor_metadata" => %{}
            }
          ],
          "last_modified" => "2024-01-01T00:00:00.000000Z",
          "uuid" => "425d9020-4d40-456d-8dd1-d1d3734e648a",
          "languages" => [
            %{
              "id" => "61f302b9-960d-4df4-8d6e-6435fd704810",
              "label" => "English",
              "variant" => nil,
              "iso_639_3" => "eng",
              "bcp_47" => nil
            }
          ],
          "first_block_id" => "c180325c-c48c-5a18-a117-634366357b29",
          "interaction_timeout" => 300,
          "vendor_metadata" => %{},
          "supported_modes" => ["RICH_MESSAGING"],
          "exit_block_id" => ""
        }
      ],
      "vendor_metadata" => %{},
      "specification_version" => "1.0.0-rc3"
    }

    sim = Simulator.new(FlowRunner.compile!(container))
    {:end, sim, []} = Simulator.start(sim)

    # Verify the enum value was sanitized into proper structure
    contact_status = get_in(sim.context.vars, ["contact", "status"])

    assert %{
             "display" => "Pending Approval",
             "value" => "PENDING_APPROVAL",
             "__value__" => "PENDING_APPROVAL"
           } = contact_status

    # Test various enum patterns
    test_cases = [
      {"ACTIVE", "Active"},
      {"PENDING_REVIEW", "Pending Review"},
      {"USER_DISABLED", "User Disabled"},
      {"HIGH_PRIORITY", "High Priority"},
      {"API_ERROR_500", "Api Error 500"},
      {"SOME_REALLY_LONG_ENUM_NAME", "Some Really Long Enum Name"}
    ]

    for {enum_value, expected_display} <- test_cases do
      container = %{
        "name" => "Test Enum #{enum_value}",
        "description" => "Test description",
        "uuid" => "66980030-a035-42da-97de-64814acbd834",
        "resources" => [],
        "flows" => [
          %{
            "label" => nil,
            "name" => "test_flow",
            "blocks" => [
              %{
                "label" => nil,
                "name" => "test_enum_#{enum_value}",
                "type" => "Core.SetContactProperty",
                "config" => %{
                  "set_contact_property" => %{
                    "property_key" => "test_field",
                    "property_value" => enum_value
                  }
                },
                "tags" => [],
                "uuid" => "c180325c-c48c-5a18-a117-634366357b29",
                "ui_metadata" => %{
                  "canvas_coordinates" => %{"x" => 0, "y" => 0}
                },
                "exits" => [
                  %{
                    "default" => true,
                    "name" => "default_exit",
                    "config" => %{},
                    "test" => "",
                    "uuid" => "1318ac38-99ed-4f2f-b15f-5daf26ce3ece",
                    "semantic_label" => "",
                    "vendor_metadata" => %{},
                    "destination_block" => nil
                  }
                ],
                "semantic_label" => nil,
                "vendor_metadata" => %{}
              }
            ],
            "last_modified" => "2024-01-01T00:00:00.000000Z",
            "uuid" => "425d9020-4d40-456d-8dd1-d1d3734e648a",
            "languages" => [
              %{
                "id" => "61f302b9-960d-4df4-8d6e-6435fd704810",
                "label" => "English",
                "variant" => nil,
                "iso_639_3" => "eng",
                "bcp_47" => nil
              }
            ],
            "first_block_id" => "c180325c-c48c-5a18-a117-634366357b29",
            "interaction_timeout" => 300,
            "vendor_metadata" => %{},
            "supported_modes" => ["RICH_MESSAGING"],
            "exit_block_id" => ""
          }
        ],
        "vendor_metadata" => %{},
        "specification_version" => "1.0.0-rc3"
      }

      sim = Simulator.new(FlowRunner.compile!(container))
      {:end, sim, []} = Simulator.start(sim)
      contact_field = get_in(sim.context.vars, ["contact", "test_field"])

      assert %{
               "display" => ^expected_display,
               "value" => ^enum_value,
               "__value__" => ^enum_value
             } = contact_field
    end
  end

  test "contact property enum field sanitization with expression" do
    # Test enum value gets sanitized when property_value is an expression
    container = %{
      "name" => "Test Enum Sanitization Expression",
      "description" => "Test description",
      "uuid" => "66980030-a035-42da-97de-64814acbd834",
      "resources" => [],
      "flows" => [
        %{
          "label" => nil,
          "name" => "test_flow",
          "blocks" => [
            %{
              "label" => nil,
              "name" => "test_enum_expression",
              "type" => "Core.SetContactProperty",
              "config" => %{
                "set_contact_property" => %{
                  "property_key" => "target_status",
                  "property_value" => "@contact.source_status"
                }
              },
              "tags" => [],
              "uuid" => "c180325c-c48c-5a18-a117-634366357b29",
              "ui_metadata" => %{
                "canvas_coordinates" => %{"x" => 0, "y" => 0}
              },
              "exits" => [
                %{
                  "default" => true,
                  "name" => "default_exit",
                  "config" => %{},
                  "test" => "",
                  "uuid" => "1318ac38-99ed-4f2f-b15f-5daf26ce3ece",
                  "semantic_label" => "",
                  "vendor_metadata" => %{},
                  "destination_block" => nil
                }
              ],
              "semantic_label" => nil,
              "vendor_metadata" => %{}
            }
          ],
          "last_modified" => "2024-01-01T00:00:00.000000Z",
          "uuid" => "425d9020-4d40-456d-8dd1-d1d3734e648a",
          "languages" => [
            %{
              "id" => "61f302b9-960d-4df4-8d6e-6435fd704810",
              "label" => "English",
              "variant" => nil,
              "iso_639_3" => "eng",
              "bcp_47" => nil
            }
          ],
          "first_block_id" => "c180325c-c48c-5a18-a117-634366357b29",
          "interaction_timeout" => 300,
          "vendor_metadata" => %{},
          "supported_modes" => ["RICH_MESSAGING"],
          "exit_block_id" => ""
        }
      ],
      "vendor_metadata" => %{},
      "specification_version" => "1.0.0-rc3"
    }

    # Initialize with a contact field containing an enum value
    initial_vars = %{"contact" => %{"source_status" => "PENDING_APPROVAL"}}
    sim = Simulator.new(FlowRunner.compile!(container))
    {:end, sim, []} = Simulator.start(sim, initial_vars)

    # Verify the enum value from the expression was sanitized into proper structure
    target_status = get_in(sim.context.vars, ["contact", "target_status"])

    assert %{
             "display" => "Pending Approval",
             "value" => "PENDING_APPROVAL",
             "__value__" => "PENDING_APPROVAL"
           } = target_status
  end

  test "contact property non-enum values remain unchanged" do
    # Test that non-enum values are not sanitized
    non_enum_cases = [
      # lowercase with underscore
      "john_doe",
      # mixed case with space
      "John Smith",
      # lowercase with numbers
      "user123",
      # with dashes
      "some-value",
      # simple lowercase
      "normaltext",
      # mixed case with underscores
      "Mixed_Case_Text",
      # starts with number
      "123NUMBER",
      # single uppercase letter
      "A",
      # empty string
      ""
    ]

    for test_value <- non_enum_cases do
      container = %{
        "name" => "Test Non-Enum Values",
        "description" => "Test description",
        "uuid" => "66980030-a035-42da-97de-64814acbd834",
        "resources" => [],
        "flows" => [
          %{
            "label" => nil,
            "name" => "test_flow",
            "blocks" => [
              %{
                "label" => nil,
                "name" => "test_non_enum",
                "type" => "Core.SetContactProperty",
                "config" => %{
                  "set_contact_property" => %{
                    "property_key" => "test_field",
                    "property_value" => test_value
                  }
                },
                "tags" => [],
                "uuid" => "c180325c-c48c-5a18-a117-634366357b29",
                "ui_metadata" => %{
                  "canvas_coordinates" => %{"x" => 0, "y" => 0}
                },
                "exits" => [
                  %{
                    "default" => true,
                    "name" => "default_exit",
                    "config" => %{},
                    "test" => "",
                    "uuid" => "1318ac38-99ed-4f2f-b15f-5daf26ce3ece",
                    "semantic_label" => "",
                    "vendor_metadata" => %{},
                    "destination_block" => nil
                  }
                ],
                "semantic_label" => nil,
                "vendor_metadata" => %{}
              }
            ],
            "last_modified" => "2024-01-01T00:00:00.000000Z",
            "uuid" => "425d9020-4d40-456d-8dd1-d1d3734e648a",
            "languages" => [
              %{
                "id" => "61f302b9-960d-4df4-8d6e-6435fd704810",
                "label" => "English",
                "variant" => nil,
                "iso_639_3" => "eng",
                "bcp_47" => nil
              }
            ],
            "first_block_id" => "c180325c-c48c-5a18-a117-634366357b29",
            "interaction_timeout" => 300,
            "vendor_metadata" => %{},
            "supported_modes" => ["RICH_MESSAGING"],
            "exit_block_id" => ""
          }
        ],
        "vendor_metadata" => %{},
        "specification_version" => "1.0.0-rc3"
      }

      sim = Simulator.new(FlowRunner.compile!(container))
      {:end, sim, []} = Simulator.start(sim)
      contact_field = get_in(sim.context.vars, ["contact", "test_field"])

      # Non-enum values should remain unchanged
      assert contact_field == test_value
    end
  end

  test "enum sanitization preserves existing contact fields" do
    # Test that existing contact fields are preserved when adding enum field
    initial_contact = %{
      "name" => "John Doe",
      "email" => "john@example.com",
      "age" => "25"
    }

    container = %{
      "name" => "Test Preserve Fields",
      "description" => "Test description",
      "uuid" => "66980030-a035-42da-97de-64814acbd834",
      "resources" => [],
      "flows" => [
        %{
          "label" => nil,
          "name" => "test_flow",
          "blocks" => [
            %{
              "label" => nil,
              "name" => "test_preserve_fields",
              "type" => "Core.SetContactProperty",
              "config" => %{
                "set_contact_property" => %{
                  "property_key" => "status",
                  "property_value" => "VERIFIED_USER"
                }
              },
              "tags" => [],
              "uuid" => "c180325c-c48c-5a18-a117-634366357b29",
              "ui_metadata" => %{
                "canvas_coordinates" => %{"x" => 0, "y" => 0}
              },
              "exits" => [
                %{
                  "default" => true,
                  "name" => "default_exit",
                  "config" => %{},
                  "test" => "",
                  "uuid" => "1318ac38-99ed-4f2f-b15f-5daf26ce3ece",
                  "semantic_label" => "",
                  "vendor_metadata" => %{},
                  "destination_block" => nil
                }
              ],
              "semantic_label" => nil,
              "vendor_metadata" => %{}
            }
          ],
          "last_modified" => "2024-01-01T00:00:00.000000Z",
          "uuid" => "425d9020-4d40-456d-8dd1-d1d3734e648a",
          "languages" => [
            %{
              "id" => "61f302b9-960d-4df4-8d6e-6435fd704810",
              "label" => "English",
              "variant" => nil,
              "iso_639_3" => "eng",
              "bcp_47" => nil
            }
          ],
          "first_block_id" => "c180325c-c48c-5a18-a117-634366357b29",
          "interaction_timeout" => 300,
          "vendor_metadata" => %{},
          "supported_modes" => ["RICH_MESSAGING"],
          "exit_block_id" => ""
        }
      ],
      "vendor_metadata" => %{},
      "specification_version" => "1.0.0-rc3"
    }

    sim = Simulator.new(FlowRunner.compile!(container))
    sim = Simulator.update_context(sim, %{"contact" => initial_contact})
    {:end, sim, []} = Simulator.start(sim)

    # Verify existing fields are preserved
    contact = sim.context.vars["contact"]
    assert contact["name"] == "John Doe"
    assert contact["email"] == "john@example.com"
    assert contact["age"] == "25"

    # Verify enum field was sanitized
    assert %{
             "display" => "Verified User",
             "value" => "VERIFIED_USER",
             "__value__" => "VERIFIED_USER"
           } = contact["status"]
  end

  test "update_dictionary" do
    # with expression value
    sim = Simulator.new(read_floip!("simulator_update_dictionary_with_expression_value"))
    {:end, sim, []} = Simulator.start(sim, %{"variables" => %{"score" => 0}})

    assert sim.block.name == "update_dictionary.variables.score"
    assert sim.block.type == "Io.Turn.UpdateDictionary"

    assert %{
             reference: "variables",
             key: "score",
             value: "variables.score + 1"
           } = sim.block.config

    # it should be updated because `variables.platform`
    # exists in the context variables
    assert get_in(sim.context.vars, ["variables", "score"]) == "1"

    # with string value
    sim = Simulator.new(read_floip!("simulator_update_dictionary_with_string_value"))

    {:end, sim, []} = Simulator.start(sim)

    assert sim.block.name == "update_dictionary.variables.platform"
    assert sim.block.type == "Io.Turn.UpdateDictionary"

    assert %{
             reference: "variables",
             key: "platform",
             value: "\"elixir\""
           } = sim.block.config

    # it should NOT be updated because `variables.platform`
    # does NOT exists in the context variables
    assert get_in(sim.context.vars, ["variables", "platform"]) == nil
  end

  test "whatsapp catalog with text only" do
    sim = Simulator.new(read_floip!("whatsapp_catalog_basic"))

    {:waiting, _sim, outputs} = Simulator.start(sim)

    # Check the catalog message text
    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("Welcome to our catalog!")

    # Check the thumbnail image is present (now uses data URI)
    assert outputs
           |> get_in([:interactive, :image])
           |> with_content_type("IMAGE")
           |> has_value("data:image/png;base64,")

    # Check the "View Catalog" button is present
    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("View Catalog")

    # Check the button has the correct event value
    button_output = outputs |> get_in([:interactive, :button]) |> hd()
    assert button_output.event_value == "view_catalog"
  end

  test "whatsapp catalog with text and footer" do
    sim = Simulator.new(read_floip!("whatsapp_catalog_with_footer"))

    {:waiting, _sim, outputs} = Simulator.start(sim)

    # Check the main catalog message
    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("Browse our products")

    # Check the footer is in its own output section (like list blocks)
    assert outputs
           |> get_in([:interactive, :footer])
           |> with_content_type("TEXT")
           |> has_value("Contact us for more info")

    # Check the interactive elements are present
    assert outputs
           |> get_in([:interactive, :image])
           |> with_content_type("IMAGE")
           |> has_value("data:image/png;base64,")

    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("View Catalog")
  end

  test "whatsapp catalog with expressions in text and footer" do
    sim = Simulator.new(read_floip!("whatsapp_catalog_with_expressions"))

    {:waiting, _sim, outputs} =
      Simulator.start(sim, %{"store_name" => "Amazing Store", "support_email" => "help@store.com"})

    # Check that expressions are evaluated in the catalog text
    assert outputs
           |> get_in([:interactive, :text])
           |> with_content_type("TEXT")
           |> has_value("Welcome to Amazing Store catalog!")

    # Check that expressions are evaluated in the footer (in its own output section)
    assert outputs
           |> get_in([:interactive, :footer])
           |> with_content_type("TEXT")
           |> has_value("Contact help@store.com")

    # Check the catalog maintains its interactive structure
    assert outputs
           |> get_in([:interactive, :image])
           |> with_content_type("IMAGE")
           |> has_value("data:image/png;base64,")

    assert outputs
           |> get_in([:interactive, :button])
           |> with_content_type("TEXT")
           |> has_value("View Catalog")
  end

  test "simulator with wait block" do
    sim = Simulator.new(read_floip!("wait"))

    {:end, _sim, outputs} = Simulator.start(sim)

    # Should have two messages: wait debug message and the actual message
    assert length(outputs) == 2

    # First output should be the wait block debug message
    [wait_output, message_output] = outputs

    assert {:message, wait_fields} = wait_output
    [wait_text] = get_in(wait_fields, [:text])
    assert wait_text.content_type == "TEXT"

    assert wait_text.value == """
           [DEBUG]
           Paused execution for 1 second(s).
           """

    # Second output should be the message after wait
    assert {:message, message_fields} = message_output
    [message_text] = get_in(message_fields, [:text])
    assert message_text.content_type == "TEXT"
    assert message_text.value == "This message appears after the wait!"
  end

  test "meta conversion with basic configuration" do
    sim = Simulator.new(read_floip!("meta_conversion_basic"))

    {:end, _sim, outputs} = Simulator.start(sim)

    # Should have two messages: meta conversion debug message and the success message
    assert length(outputs) == 2

    # First output should be the meta conversion debug message
    [conversion_output, message_output] = outputs

    assert {:message, conversion_fields} = conversion_output
    [conversion_text] = get_in(conversion_fields, [:text])
    assert conversion_text.content_type == "TEXT"

    # Check that the debug output contains the event name and user_data as raw data
    assert conversion_text.value =~ "Meta Conversion event sent:"
    assert conversion_text.value =~ "event_name: Purchase"
    assert conversion_text.value =~ "user_data:"
    # user_data is displayed as-is (as a map in this case)
    assert conversion_text.value =~ ~s("email" => "user@example.com")
    assert conversion_text.value =~ ~s("phone" => "+1234567890")

    # Second output should be the success message
    assert {:message, message_fields} = message_output
    [message_text] = get_in(message_fields, [:text])
    assert message_text.content_type == "TEXT"
    assert message_text.value == "Conversion event sent successfully!"
  end

  test "meta conversion with optional parameters" do
    sim = Simulator.new(read_floip!("meta_conversion_with_optional_params"))

    {:end, _sim, outputs} = Simulator.start(sim)

    # Should have one message: meta conversion debug message
    assert length(outputs) == 1

    [conversion_output] = outputs

    assert {:message, conversion_fields} = conversion_output
    [conversion_text] = get_in(conversion_fields, [:text])
    assert conversion_text.content_type == "TEXT"

    # Check that the debug output contains user_data and optional_fields as raw data
    assert conversion_text.value =~ "Meta Conversion event sent:"
    assert conversion_text.value =~ "event_name: AddToCart"
    assert conversion_text.value =~ "user_data:"
    # user_data is displayed as-is (as a map in this case)
    assert conversion_text.value =~ ~s("email" => "customer@example.com")
    assert conversion_text.value =~ ~s("phone" => "+9876543210")
    assert conversion_text.value =~ ~s("fn" => "John")
    assert conversion_text.value =~ ~s("ln" => "Doe")

    # Check that the debug output contains optional_fields as-is (as a map in this case)
    assert conversion_text.value =~ "optional_fields:"
    assert conversion_text.value =~ ~s("value" => "99.99")
    assert conversion_text.value =~ ~s("currency" => "USD")
    assert conversion_text.value =~ ~s("content_name" => "Premium Widget")
    assert conversion_text.value =~ ~s("event_time" => "1234567890")
    assert conversion_text.value =~ ~s("action_source" => "website")

    assert conversion_text.value =~
             ~s("event_source_url" => "https://example.com/products/widget")
  end

  test "meta conversion with nested optional fields" do
    sim = Simulator.new(read_floip!("meta_conversion_with_nested_fields"))

    {:end, _sim, outputs} = Simulator.start(sim)

    assert length(outputs) == 1

    [conversion_output] = outputs

    assert {:message, conversion_fields} = conversion_output
    [conversion_text] = get_in(conversion_fields, [:text])
    assert conversion_text.content_type == "TEXT"

    # Check that the debug output contains the event name and user_data
    assert conversion_text.value =~ "Meta Conversion event sent:"
    assert conversion_text.value =~ "event_name: Purchase"
    assert conversion_text.value =~ "user_data:"
    assert conversion_text.value =~ ~s("client_ip_address" => "1.1.1.1")
    assert conversion_text.value =~ ~s("client_user_agent" => "test user agent")

    # Check that the debug output contains optional_fields with nested custom_data
    assert conversion_text.value =~ "optional_fields:"
    assert conversion_text.value =~ ~s("value" => "199.99")
    assert conversion_text.value =~ ~s("currency" => "USD")

    # Verify nested custom_data is properly evaluated and displayed
    assert conversion_text.value =~ ~s("custom_data" =>)
    assert conversion_text.value =~ ~s("product_id" => "SKU123")
    assert conversion_text.value =~ ~s("category" => "Electronics")
    assert conversion_text.value =~ ~s("brand" => "TestBrand")
  end

  describe "output_block/2 for Io.Turn.AI.Agent" do
    defp agent_sim(vars) do
      %Simulator{
        context: %FlowRunner.Context{
          vars: vars,
          language: "eng",
          waiting_for_user_input: false
        }
      }
    end

    defp agent_block(name) do
      %FlowRunner.Spec.Block{
        type: "Io.Turn.AI.Agent",
        name: name,
        uuid: "test-uuid",
        exits: [],
        config: %{}
      }
    end

    test "returns message output when action is end_conversation with final message" do
      sim =
        agent_sim(%{"ref_Agent" => %{"action" => "end_conversation", "response" => "Goodbye!"}})

      block = agent_block("ref_Agent")

      assert {{:message, [text: [output]]}, _sim} = Simulator.output_block(sim, block)

      assert %Simulator.Output{content_type: "TEXT", mime_type: "text/plain", value: "Goodbye!"} =
               output
    end

    test "returns message output when action is a recognized intent with final message" do
      sim =
        agent_sim(%{
          "ref_Agent" => %{"action" => "book_appointment", "response" => "Routing you now!"}
        })

      block = agent_block("ref_Agent")

      assert {{:message, [text: [output]]}, _sim} = Simulator.output_block(sim, block)
      assert %Simulator.Output{value: "Routing you now!"} = output
    end

    test "returns nil when action is continue_conversation" do
      sim =
        agent_sim(%{
          "ref_Agent" => %{"action" => "continue_conversation", "response" => "How can I help?"}
        })

      block = agent_block("ref_Agent")

      assert {nil, _sim} = Simulator.output_block(sim, block)
    end

    test "returns nil when response is empty" do
      sim = agent_sim(%{"ref_Agent" => %{"action" => "end_conversation", "response" => ""}})
      block = agent_block("ref_Agent")

      assert {nil, _sim} = Simulator.output_block(sim, block)
    end

    test "returns nil when vars are not set for the block" do
      sim = agent_sim(%{})
      block = agent_block("ref_Agent")

      assert {nil, _sim} = Simulator.output_block(sim, block)
    end
  end
end
