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
  @catalog_placeholder_data_uri "data:image/png;base64,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"

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

    # Create message output
    # NOTE: This is a warning since the catalog message type isn't fully supported in the simulator
    text_output =
      "[WARNING]\nThis message type isn't fully supported by the simulator, try previewing this on your phone.\n\n#{catalog_text}"

    text_output = %Output{
      mime_type: "text/plain",
      raw_value: text_output,
      value: text_output,
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

  def output_block(sim, %{type: "Io.Turn.WhatsAppRequestLocation", config: config}) do
    request_location_config = config.request_location

    # Resolve the request location text resource and evaluate it
    text_resource = fetch_resource_by_uuid!(sim, request_location_config.text)
    [text_resource_value] = fetch_resource_values(sim, text_resource, "TEXT")
    request_text = resource_value_output(sim, text_resource_value).value

    # Create message output
    # NOTE: This is a warning since the catalog message type isn't fully supported in the simulator
    text_output =
      "[WARNING]\nThis message type isn't fully supported by the simulator, try previewing this on your phone.\n\n#{request_text}"

    # Create the main text output
    text_output = %Output{
      mime_type: "text/plain",
      raw_value: text_output,
      value: text_output,
      content_type: "TEXT"
    }

    # Create the "Send location" button
    button_output = %Output{
      mime_type: "text/plain",
      raw_value: "Send location",
      value: "Send location",
      event_value: "send_location",
      content_type: "TEXT"
    }

    outputs = [
      text: [text_output],
      button: [button_output]
    ]

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

  def output_block(sim, %{type: "Io.Turn.MetaConversion", config: config}) do
    conversion_config = config.conversion
    context_vars = if sim.context, do: sim.context.vars, else: %{}

    # Evaluate event_name directly as an expression
    event_name =
      Expression.evaluate_as_string!(
        conversion_config.event_name,
        context_vars,
        sim.callbacks_module
      )

    # Evaluate user_data values while keeping the original structure (map or keyword list)
    user_data =
      evaluate_conversion_fields(conversion_config.user_data, context_vars, sim.callbacks_module)

    # Evaluate optional_fields values while keeping the original structure
    optional_fields_output =
      if conversion_config.optional_fields not in [nil, %{}, ""] do
        optional_fields =
          evaluate_conversion_fields(
            conversion_config.optional_fields,
            context_vars,
            sim.callbacks_module
          )

        "\n  optional_fields: #{inspect(optional_fields)}"
      else
        ""
      end

    debug_value = """
    [DEBUG]
    Meta Conversion event sent:
      event_name: #{event_name}
      user_data: #{inspect(user_data)}#{optional_fields_output}
    """

    text_output = %Output{
      mime_type: "text/plain",
      raw_value: debug_value,
      value: debug_value,
      content_type: "TEXT"
    }

    {{:message, text: [text_output]}, sim}
  end

  def output_block(sim, %{type: "Io.Turn.Wait", config: %{seconds: seconds}}) do
    evaluated_seconds =
      if is_binary(seconds) do
        Expression.evaluate_block!(seconds, sim.context.vars, sim.callbacks_module)
      else
        seconds
      end

    debug_value = """
    [DEBUG]
    Paused execution for #{evaluated_seconds} second(s).
    """

    # Wait for the number of seconds specified in the wait block
    Process.sleep(evaluated_seconds * 1000)

    text_output = %Output{
      mime_type: "text/plain",
      raw_value: debug_value,
      value: debug_value,
      content_type: "TEXT"
    }

    {{:message, text: [text_output]}, sim}
  end

  def output_block(sim, %{type: type}) do
    Logger.info("Simulator unable to output block of type #{inspect(type)}")
    {nil, sim}
  end

  # Helper function to evaluate conversion field values and return as a map
  defp evaluate_conversion_fields(fields, context_vars, callbacks_module) do
    fields
    |> normalize_to_map()
    |> evaluate_map_values(context_vars, callbacks_module)
  end

  # Convert various data types to a map
  defp normalize_to_map(fields) when is_map(fields), do: fields
  defp normalize_to_map(fields) when is_list(fields), do: Enum.into(fields, %{})

  defp normalize_to_map(fields) when is_binary(fields) do
    case Jason.decode(fields) do
      {:ok, decoded} when is_map(decoded) -> decoded
      _ -> %{}
    end
  end

  defp normalize_to_map(_), do: %{}

  # Evaluate all values in a map as expressions
  defp evaluate_map_values(map, context_vars, callbacks_module) do
    Map.new(map, fn {key, value_expr} ->
      evaluated_value =
        Expression.evaluate_as_string!(to_string(value_expr), context_vars, callbacks_module)

      {key, evaluated_value}
    end)
  end

  defp extract_buttons(template_components, sim) do
    buttons = Enum.filter(template_components, &(&1.type == "button" and &1.sub_type != "url"))

    if buttons != [] do
      template_components
      |> Enum.filter(&(&1.type == "button"))
      |> Enum.map(fn button -> Map.get(button, :parameters, []) end)
      |> Enum.filter(fn [%{language: language} | _] ->
        Expression.evaluate_as_string!(language, sim.context.vars, sim.callbacks_module) ==
          sim.language.iso_639_3
      end)
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
