defmodule FlowRunner.Simulator do
  @moduledoc """
  A simulator for interacting with the Flow Runner.

  This is used for testing purposes and ca be used to build
  a simulator that the user can experiment with to test the
  service they are building.
  """

  require Logger

  # Base64 encoded placeholder image for WhatsApp catalog simulation
  # This ensures the image is always available regardless of the consuming application's static assets
  @catalog_placeholder_data_uri "data:image/jpeg;base64,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"

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

  @max_recursion 1_000
  @spec next(t(), String.t() | nil, list, non_neg_integer) ::
          {:end, t(), list}
          | {:waiting, t(), list}
          | {:error, t(), reason :: String.t()}
  def next(sim, user_input \\ nil, acc \\ [], recursion \\ 0)

  def next(sim, _user_input, _acc, recursion) when recursion > @max_recursion do
    {:error, sim, "Exceeded max recursion calls allowed (#{@max_recursion})"}
  end

  def next(sim, user_input, acc, recursion) do
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
          next(sim, nil, acc, recursion + 1)
        end

      {:end, container, flow, last_block, context} ->
        sim = %{sim | container: container, flow: flow, context: context}
        sim = track_output(sim, last_block)
        {:end, sim, Enum.reverse(acc)}

      {:error, reason} when is_binary(reason) ->
        {:error, sim, reason}
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
        param.type in ["document", "video", "image"] and
          param.language == sim.language.iso_639_3
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

  def output_block(sim, %{type: "Io.Turn.WhatsAppCatalog", config: config}) do
    catalog_config = config.catalog

    # Resolve the catalog text resource and evaluate it
    text_resource = fetch_resource_by_uuid!(sim, catalog_config.text)
    [text_resource_value] = fetch_resource_values(sim, text_resource, "TEXT")
    catalog_text = resource_value_output(sim, text_resource_value).value

    # Create a placeholder thumbnail image (simulating catalog thumbnail)
    # Uses embedded data URI to ensure image is always available regardless of static assets configuration
    catalog_thumbnail_image = @catalog_placeholder_data_uri

    image_output = %Output{
      mime_type: "image/jpeg",
      raw_value: catalog_thumbnail_image,
      value: catalog_thumbnail_image,
      content_type: "IMAGE"
    }

    # Create the main text output
    text_output = %Output{
      mime_type: "text/plain",
      raw_value: catalog_text,
      value: catalog_text,
      content_type: "TEXT"
    }

    # Create the "View Catalog" button
    button_output = %Output{
      mime_type: "text/plain",
      raw_value: "View Catalog",
      value: "View Catalog",
      event_value: "view_catalog",
      content_type: "TEXT"
    }

    # Handle footer metadata
    catalog_metadata =
      if Map.has_key?(catalog_config, :footer) do
        footer_resource = fetch_resource_by_uuid!(sim, catalog_config.footer)
        [footer_resource_value] = fetch_resource_values(sim, footer_resource, "TEXT")
        footer_text = resource_value_output(sim, footer_resource_value).value
        %{"footer" => footer_text}
      else
        %{}
      end

    metadata_outputs = get_interactive_metadata_resource_outputs(sim, catalog_metadata)

    outputs =
      [
        text: [text_output],
        image: [image_output],
        button: [button_output]
      ] ++ metadata_outputs

    {{:interactive, outputs}, sim}
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
