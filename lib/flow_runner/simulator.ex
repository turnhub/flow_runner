defmodule FlowRunner.Simulator do
  @moduledoc """
  A simulator for interacting with the Flow Runner.

  This is used for testing purposes and ca be used to build
  a simulator that the user can experiment with to test the
  service they are building.
  """

  require Logger

  defstruct uuid: nil,
            stacks: [],
            language: nil,
            container: nil,
            context: nil,
            mode: nil,
            flow: nil,
            block: nil,
            history: [],
            user_inputs: [],
            last_user_input: nil,
            callbacks_module: Expression.Callbacks.Standard

  @type t :: %__MODULE__{}
  @type quick_reply_choice :: %{
          required(:name) => String.t(),
          required(:test) => String.t(),
          required(:prompt) => String.t()
        }

  defmodule Output do
    @moduledoc """
    The output of a state in simulator step
    """
    @type t :: %__MODULE__{
            content_type: String.t() | nil,
            mime_type: String.t() | nil,
            raw_value: String.t() | nil,
            value: String.t() | nil,
            event_value: String.t() | nil
          }
    defstruct content_type: nil, mime_type: nil, raw_value: nil, value: nil, event_value: nil
  end

  def new(container, callbacks_module \\ Expression.Callbacks.Standard),
    do: %__MODULE__{
      uuid: UUID.uuid4(),
      callbacks_module: callbacks_module,
      container: container
    }

  def start(sim, vars \\ %{}, language_code \\ "eng", mode \\ "RICH_MESSAGING") do
    next(update_context(sim, vars, language_code, mode))
  end

  def update_context(sim, vars \\ %{}, language_code \\ "eng", mode \\ "RICH_MESSAGING") do
    [first_flow | _] = sim.container.flows
    [first_language | _] = first_flow.languages

    # get the language for the language_code, fallback to the first_language if none match
    language = Enum.find(first_flow.languages, first_language, &(&1.iso_639_3 == language_code))

    {:ok, context} =
      if sim.context,
        do: {:ok, sim.context},
        else:
          FlowRunner.create_context(
            sim.container,
            first_flow.uuid,
            language.iso_639_3,
            mode,
            vars
          )

    original_vars = context.vars
    updated_vars = Map.merge(original_vars, vars)

    %{
      sim
      | language: language,
        context: %{context | vars: updated_vars, language: language_code},
        mode: mode
    }
  end

  @spec next(t(), String.t() | nil, list) ::
          {:end, t(), list}
          | {:waiting, t(), list}
          | {:error, reason :: String.t()}
  def next(sim, user_input \\ nil, acc \\ []) do
    # The use of templates with buttons that lead to different cards in the simulator is
    # a bit complex. Because while we want to show the name of the destination card as
    # the text of the button, what we really need to select the correct button is its
    # index, so at this point we have to convert the user input to the index of the
    # button they selected.
    user_input =
      if has_template_buttons?(sim) do
        index = get_button_index(sim, user_input)

        "template-btn-idx-#{index}"
      else
        user_input
      end

    sim = track_input(sim, user_input)

    case FlowRunner.next_block(sim.container, sim.context, user_input) do
      {:ok, floip_container, flow, block, context} ->
        sim = %{
          sim
          | container: floip_container,
            block: block,
            flow: flow,
            context: context
        }

        {sim, acc} =
          case output_block(sim, block) do
            {nil, sim} -> {sim, acc}
            {output, sim} -> {sim, [output | acc]}
          end

        if context.waiting_for_user_input do
          {:waiting, track_output(sim, block), Enum.reverse(acc)}
        else
          next(sim, nil, acc)
        end

      {:end, container, flow, last_block, context} ->
        sim = %{sim | container: container, flow: flow, context: context}
        sim = track_output(sim, last_block)
        {:end, sim, Enum.reverse(acc)}

      {:error, reason} when is_binary(reason) ->
        {:error, reason}
    end
  end

  defp has_template_buttons?(%{
         block: %{
           type: "Io.Turn.WhatsAppTemplateMessage",
           config: %{template: %{components: components}}
         }
       }),
       do: Enum.any?(components, &(&1.type == "button" and &1.sub_type != "url"))

  defp has_template_buttons?(_sim), do: false

  defp get_button_index(sim, user_input) do
    option =
      sim.block.config.template.components
      |> Enum.filter(fn
        %{parameters: [parameter], type: "button"} -> parameter[:payload] == user_input
        _other -> false
      end)
      |> List.first()

    if option, do: Map.get(option, :index), else: -1
  end

  def resource_value_output(
        sim,
        %{mime_type: mime_type, value: value, content_type: content_type},
        event_value \\ nil
      ),
      do: %Output{
        mime_type: mime_type,
        raw_value: value,
        value: Expression.evaluate_as_string!(value, sim.context.vars, sim.callbacks_module),
        content_type: content_type,
        event_value: event_value
      }

  def output(_sim, %{block: nil}), do: nil

  def output_block(sim, %{type: type, config: %{prompt: prompt}})
      when type in ["MobilePrimitives.Message", "MobilePrimitives.OpenResponse"] do
    message_resource = fetch_resource_by_uuid!(sim, prompt)

    fields =
      [
        text: {"TEXT", "text/plain"},
        document: {"TEXT", "application/pdf"},
        image: {"IMAGE", nil},
        video: {"VIDEO", nil},
        audio: {"AUDIO", nil}
      ]
      |> Enum.reduce([], fn {key, {content_type, mime_type}}, acc ->
        items =
          fetch_resource_values(sim, message_resource, content_type, mime_type)
          |> Enum.map(&resource_value_output(sim, &1))

        if Enum.any?(items) do
          Keyword.put(acc, key, items)
        else
          acc
        end
      end)

    {{:message, fields}, sim}
  end

  def output_block(sim, %{type: type, config: %{prompt: prompt}} = output)
      when type in ["Io.Turn.DynamicSelectOneResponse", "MobilePrimitives.SelectOneResponse"] do
    message_resource = fetch_resource_by_uuid!(sim, prompt)

    text_resource_outputs =
      sim
      |> fetch_resource_values(message_resource, "TEXT")
      |> Enum.map(&resource_value_output(sim, &1))

    case text_resource_outputs do
      [_button_text] ->
        output_quickreply_block(sim, output)

      [_text, _call_to_action] ->
        if Enum.any?(text_resource_outputs, &(&1.mime_type == "application/pdf")) do
          output_quickreply_block(sim, output)
        else
          output_listreply_block(sim, output)
        end
    end
  end

  def output_block(sim, %{type: "Core.Case"}) do
    {nil, sim}
  end

  def output_block(sim, %{
        type: "Io.Turn.ScheduleFlow",
        config: %{flow_id: flow_id, schedule_in: schedule_in_block}
      }) do
    context_vars = if sim.context, do: sim.context.vars, else: %{}

    schedule_in =
      Expression.evaluate_block!(schedule_in_block, context_vars, sim.callbacks_module)

    debug_value = """
    [DEBUG]
    Stack with ID #{flow_id} is scheduled to run in #{schedule_in} seconds.
    Note: it won't actually run in this simulator.
    """

    {{:message,
      text: [
        %Output{
          mime_type: "text/plain",
          raw_value: debug_value,
          value: debug_value,
          content_type: "TEXT"
        }
      ]}, sim}
  end

  def output_block(sim, %{
        type: "Io.Turn.WhatsAppSendFlow",
        config: %{
          flow: %{
            id: flow_id_resource_uuid,
            cta: cta_resource_uuid,
            screen: screen_resource_uuid
          }
        }
      }) do
    flow_resource = fetch_resource_by_uuid!(sim, flow_id_resource_uuid)
    cta_resource = fetch_resource_by_uuid!(sim, cta_resource_uuid)
    screen_resource = fetch_resource_by_uuid!(sim, screen_resource_uuid)

    [flow_id] =
      sim
      |> fetch_resource_values(flow_resource, "TEXT")
      |> Enum.map(&resource_value_output(sim, &1))

    [cta] =
      sim
      |> fetch_resource_values(cta_resource, "TEXT")
      |> Enum.map(&resource_value_output(sim, &1))

    [screen] =
      sim
      |> fetch_resource_values(screen_resource, "TEXT")
      |> Enum.map(&resource_value_output(sim, &1))

    debug_value = """
    [DEBUG]
    Flow with ID #{inspect(flow_id.value)} is sent to the phone using #{inspect(cta.value)} as the call to action.
    It will start with the screen #{inspect(screen.value)}.

    Note: it won't actually run in this simulator.
    """

    {{:message,
      text: [
        %Output{
          mime_type: "text/plain",
          raw_value: debug_value,
          value: debug_value,
          content_type: "TEXT"
        }
      ]}, sim}
  end

  def output_block(sim, %{
        type: "Io.Turn.ScheduleFlow",
        config: %{flow_id: flow_id, schedule_at: schedule_at_block}
      }) do
    context_vars = if sim.context, do: sim.context.vars, else: %{}

    schedule_at =
      Expression.evaluate_block!(schedule_at_block, context_vars, sim.callbacks_module)

    debug_value = """
    [DEBUG]
    Stack with ID #{flow_id} is scheduled to run on #{Calendar.strftime(schedule_at, "%a, %B %d %Y %I:%M %p")}.
    Note: it won't actually run in this simulator.
    """

    {{:message,
      text: [
        %Output{
          mime_type: "text/plain",
          raw_value: debug_value,
          value: debug_value,
          content_type: "TEXT"
        }
      ]}, sim}
  end

  def output_block(sim, %{
        type: "Io.Turn.ScheduleFlow",
        config: %{flow_id: flow_id}
      }) do
    debug_value = """
    [DEBUG]
    All runs for Stack with ID #{flow_id} will be cancelled.
    """

    {{:message,
      text: [
        %Output{
          mime_type: "text/plain",
          raw_value: debug_value,
          value: debug_value,
          content_type: "TEXT"
        }
      ]}, sim}
  end

  def output_block(sim, %{type: "Core.SetContactProperty", config: config}) do
    context_vars = if sim.context, do: sim.context.vars, else: %{}
    key = config.set_contact_property.property_key

    value =
      Expression.evaluate_as_string!(
        config.set_contact_property.property_value,
        context_vars,
        sim.callbacks_module
      )

    contact = Map.get(context_vars, "contact", %{})
    updated_contact = Map.put(contact, key, value)
    updated_vars = Map.put(context_vars, "contact", updated_contact)
    language_code = if key == "language", do: value, else: sim.context.language

    {nil, update_context(sim, updated_vars, language_code)}
  end

  def output_block(sim, %{type: "Io.Turn.UpdateDictionary", config: config}) do
    context_vars = sim.context.vars || %{}

    dictionary_keys =
      config.reference
      |> String.split(".")
      |> Enum.concat([config.key])

    value =
      Expression.evaluate_as_string!("@(#{config.value})", context_vars, sim.callbacks_module)

    updated_vars =
      if get_in(context_vars, dictionary_keys) do
        put_in(context_vars, dictionary_keys, value)
      else
        context_vars
      end

    {nil, update_context(sim, updated_vars)}
  end

  def output_block(sim, %{type: "Io.Turn.WhatsAppTemplateMessage", config: config}) do
    context_vars = if sim.context, do: sim.context.vars, else: %{}
    template_config = config.template

    template_name =
      Expression.evaluate_block!(template_config.name, context_vars, sim.callbacks_module)

    template_language =
      Expression.evaluate_block!(
        template_config.language.code,
        context_vars,
        sim.callbacks_module
      )

    # We don't have access to the list of templates in the simulator
    # so we just output a debug message to signal the fact that
    # a message template will be sent in a real-world scenario.
    debug_value = "[DEBUG]\nTemplate #{template_name} sent with language #{template_language}."

    template_components = Map.get(template_config, :components, [])

    body_params =
      template_components
      |> Enum.find(%{}, &(&1.type == "body"))
      |> Map.get(:parameters, [])
      |> Enum.filter(fn parameter ->
        parameter[:language] == sim.language.iso_639_3
      end)
      |> Enum.map_join(", ", fn %{text: param} ->
        param
        |> Expression.evaluate_block!(context_vars, sim.callbacks_module)
        |> to_string()
      end)

    debug_value =
      if body_params != "",
        do: debug_value <> "\nBody parameters: [#{body_params}]",
        else: debug_value

    header_params =
      template_components
      |> Enum.find(%{}, &(&1.type == "header"))
      |> Map.get(:parameters, [])
      |> Enum.filter(&(&1[:language] == sim.language.iso_639_3))

    header_text_params =
      header_params
      |> Enum.filter(&(&1.type == "text" && &1.language == sim.language.iso_639_3))
      |> Enum.map_join(", ", fn %{text: param} ->
        param
        |> Expression.evaluate_block!(context_vars, sim.callbacks_module)
        |> to_string()
      end)

    debug_value =
      if header_text_params != "",
        do: debug_value <> "\nHeader parameters: [#{header_text_params}]",
        else: debug_value

    header_media_param =
      Enum.find(header_params, fn param ->
        param.type in ["document", "video", "image"]
          and param.language == sim.language.iso_639_3
      end)

    media_link =
      if header_media_param do
        type_key = header_media_param.type |> String.to_existing_atom()

        header_media_param
        |> get_in([type_key, :link])
        |> Expression.evaluate_block!()
        |> to_string()
      end

    debug_value =
      if media_link,
        do: debug_value <> "\nMedia link: #{media_link}",
        else: debug_value

    button_params = extract_buttons(template_components, sim)

    if button_params do
      debug_value =
        debug_value <>
          "\n\nThe buttons represented here are not necessarily the same as the ones in the real template. Please double check the template buttons when running the flow in a real-world scenario."

      button_outputs =
        Enum.map(button_params, fn button ->
          %Output{
            mime_type: "text/plain",
            raw_value: button,
            value: button,
            event_value: button,
            content_type: "TEXT"
          }
        end)

      {{:message,
        text: [
          %Output{
            mime_type: "text/plain",
            raw_value: debug_value,
            value: debug_value,
            content_type: "TEXT"
          }
        ],
        button: button_outputs}, sim}
    else
      {{:message,
        text: [
          %Output{
            mime_type: "text/plain",
            raw_value: debug_value,
            value: debug_value,
            content_type: "TEXT"
          }
        ]}, sim}
    end
  end

  def output_block(sim, %{type: "Core.Log", config: %{message: text_resource_uuid}}) do
    log_resource = fetch_resource_by_uuid!(sim, text_resource_uuid)

    log_resource_outputs =
      sim
      |> fetch_resource_values(log_resource, "TEXT")
      |> Enum.map(&resource_value_output(sim, &1))

    {{:log, text: log_resource_outputs}, sim}
  end

  def output_block(sim, %{
        type: "Io.Turn.SendContentMessage",
        config: %{
          content: %{
            uuid: content_uuid_resource_uuid,
            wait_for_input: _wait_for_input_resource_uuid
          }
        }
      }) do
    content_resource = fetch_resource_by_uuid!(sim, content_uuid_resource_uuid)

    content_resource_outputs =
      sim
      |> fetch_resource_values(content_resource, "TEXT")
      |> Enum.map(&resource_value_output(sim, &1))
      |> Enum.map(fn content_resource_output ->
        debug_value = "[DEBUG]\nContent #{inspect(content_resource_output.value)} sent."

        %Output{
          mime_type: "text/plain",
          raw_value: debug_value,
          value: debug_value,
          content_type: "TEXT"
        }
      end)

    {{:message, text: content_resource_outputs}, sim}
  end

  def output_block(sim, %{type: type}) do
    Logger.info("Simulator unable to output block of type #{inspect(type)}")
    {nil, sim}
  end

  defp extract_buttons(template_components, sim) do
    buttons = Enum.filter(template_components, &(&1.type == "button" and &1.sub_type != "url"))

    if buttons != [] do
      template_components
      |> Enum.filter(&(&1.type == "button"))
      |> Enum.map(fn button -> Map.get(button, :parameters, []) end)
      |> Enum.filter(fn [%{language: language} | _] -> language == sim.language.iso_639_3 end)
      |> Enum.reverse()
      |> List.flatten()
      |> Enum.map(fn %{payload: payload} -> payload end)
    else
      nil
    end
  end

  @spec get_vendor(map, key :: String.t() | [String.t()]) :: term
  def get_vendor(vendor_metadata, key) when is_binary(key) do
    get_vendor(vendor_metadata, [key])
  end

  def get_vendor(vendor_metadata, keys) when is_list(keys) do
    # This is hard coded to a version number but in Turn.io the version
    # is read from an internal version identifier. That however hasn't
    # changed since it was introduced. Leaving it hard coded here to help
    # move the the simulator into the flow runner repository.
    get_in(vendor_metadata, ["io", "turn", "stacks_dsl", "0.1.0"] ++ keys)
  end

  @doc """
  Generate the list of options available for a static quick reply block.

  *IMPORTANT*: We use the button labels as the values here.
  """
  @spec generate_choices_for_static_quick_replies(t(), [quick_reply_choice]) :: [Output.t()]
  def generate_choices_for_static_quick_replies(sim, choices) do
    Enum.map(choices, fn %{prompt: prompt} ->
      resource = fetch_resource_by_uuid!(sim, prompt)
      [resource_value] = fetch_resource_values(sim, resource, "TEXT")
      resource_value_output(sim, resource_value, resource_value.value)
    end)
  end

  @doc """
  Generate the list of options available for a dynamic quick reply block.

  *IMPORTANT*: We use the button name as the values here.
  """
  @spec generate_choices_for_dynamic_quick_replies(t(), [quick_reply_choice]) :: [Output.t()]
  def generate_choices_for_dynamic_quick_replies(sim, choices) do
    Enum.map(choices, fn %{name: name, prompt: prompt} ->
      resource = fetch_resource_by_uuid!(sim, prompt)
      [resource_value] = fetch_resource_values(sim, resource, "TEXT")
      resource_value_output(sim, resource_value, name)
    end)
  end

  def output_quickreply_block(sim, %{
        type: type,
        config: %{prompt: prompt, choices: choices},
        vendor_metadata: vendor_metadata
      }) do
    message_resource = fetch_resource_by_uuid!(sim, prompt)

    resource_outputs =
      Enum.reduce(["IMAGE", "VIDEO", "TEXT"], [], fn type, resources_acc ->
        resource_outputs =
          case fetch_resource_values(sim, message_resource, type) do
            [] -> []
            resource_values -> map_buttons_resource_outputs(sim, resource_values, type)
          end

        resources_acc ++ resource_outputs
      end)

    button_resource_outputs =
      if type == "Io.Turn.DynamicSelectOneResponse" do
        generate_choices_for_dynamic_quick_replies(sim, choices)
      else
        generate_choices_for_static_quick_replies(sim, choices)
      end

    buttons_metadata = get_vendor(vendor_metadata, "buttons_metadata") || %{}

    metadata_outputs = get_interactive_metadata_resource_outputs(sim, buttons_metadata)

    outputs = [{:button, button_resource_outputs} | resource_outputs ++ metadata_outputs]

    {{:interactive, outputs}, sim}
  end

  def output_listreply_block(sim, %{
        config: %{prompt: prompt, choices: choices},
        vendor_metadata: vendor_metadata
      }) do
    message_resource = fetch_resource_by_uuid!(sim, prompt)

    [text_resource_output, call_to_action_output] =
      fetch_resource_values(sim, message_resource, "TEXT")
      |> Enum.map(&resource_value_output(sim, &1))

    button_resource_outputs =
      Enum.map(choices, fn %{prompt: prompt} ->
        resource = fetch_resource_by_uuid!(sim, prompt)
        [resource_value] = fetch_resource_values(sim, resource, "TEXT")
        resource_value_output(sim, resource_value, resource_value.value)
      end)

    list_metadata = get_vendor(vendor_metadata, "list_metadata") || %{}
    metadata_outputs = get_interactive_metadata_resource_outputs(sim, list_metadata)

    outputs =
      [
        text: [text_resource_output],
        list_call_to_action: [call_to_action_output],
        list: button_resource_outputs
      ] ++ metadata_outputs

    {{:interactive, outputs}, sim}
  end

  def history(sim) do
    Enum.map(sim.history, fn {user_input, blocks} ->
      {user_input,
       Enum.map(blocks, fn block ->
         {block, _sim} = output_block(sim, block)
         block
       end)}
    end)
  end

  def fetch_resource_by_uuid!(sim, uuid) do
    {:ok, resource} = FlowRunner.fetch_resource_by_uuid(sim.container, uuid)
    resource
  end

  def fetch_resource_values(sim, resource, content_type, mime_type \\ nil) do
    Enum.filter(
      resource.values,
      &(&1.content_type == content_type and
          &1.language_id == sim.language.id and
          (is_nil(mime_type) or &1.mime_type == mime_type))
    )
  end

  @doc """
  Keep track of the inputs received for the simulator, updating the
  last_user_input if it's not nil.
  """
  @spec track_input(t, String.t() | nil) :: t
  def track_input(sim, nil), do: %{sim | user_inputs: [nil | sim.user_inputs]}

  def track_input(sim, user_input),
    do: %{sim | user_inputs: [user_input | sim.user_inputs], last_user_input: user_input}

  @doc """
  Keep track of the blocks generated as output and keep them aligned with the original input
  that was received which triggered this block.

  Multiple blocks may be output
  """
  @spec track_output(t, FlowRunner.Spec.Block.t() | nil) :: t
  def track_output(%{history: []} = sim, output),
    do: %{sim | history: [{sim.last_user_input, [output]}]}

  def track_output(
        %{last_user_output: last_user_input, history: [{last_user_input, history} | history]} =
          sim,
        output
      ),
      do: %{sim | history: [{last_user_input, [output | history]} | history]}

  def track_output(sim, output),
    do: %{sim | history: [{sim.last_user_input, [output]} | sim.history]}

  defp map_buttons_resource_outputs(sim, [resource_value], type) do
    item_type = String.downcase(type) |> String.to_existing_atom()
    [{item_type, [resource_value_output(sim, resource_value)]}]
  end

  defp map_buttons_resource_outputs(sim, [resource_one, resource_two], _type)
       when "application/pdf" in [resource_one.mime_type, resource_two.mime_type] do
    Enum.map([resource_one, resource_two], fn resource ->
      # We do this because the FLOIP Spec doesn't have the concept of a "DOCUMENT",
      # so any document coming from FLOIP is set as a "TEXT". Here we are
      # mapping it to an actual document link.
      item_type = if resource.mime_type == "application/pdf", do: :document, else: :text

      {item_type, [resource_value_output(sim, resource)]}
    end)
  end

  defp get_interactive_metadata_resource_outputs(sim, metadata) do
    Enum.reduce(metadata, [], fn {type, text}, acc ->
      if type in ["header", "footer"] do
        resource_output =
          resource_value_output(
            sim,
            %{mime_type: "text/plain", value: text, content_type: "TEXT"},
            nil
          )

        [{String.to_existing_atom(type), [resource_output]} | acc]
      else
        acc
      end
    end)
  end
end
