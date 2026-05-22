defmodule FlowRunner.CustomBlocks.DynamicSelectOneResponse do
  @moduledoc """
  A custom FLOIP block for dynamically generating the
  list of buttons available but at runtime.
  """
  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator

  @impl true
  def validate_config!(
        %{
          "prompt" => prompt,
          "destination_block" => destination_block,
          "choice_expression" => expression
        } = config
      ) do
    %{
      prompt: prompt,
      destination_block: destination_block,
      choice_expression: expression,
      # At runtime, we may receive a configuration that already was generated
      # handle that gracefully by keeping it in place
      choices:
        config
        |> Map.get("choices", [])
        |> Enum.map(fn %{"name" => name, "test" => test, "prompt" => prompt} ->
          %{name: name, test: test, prompt: prompt}
        end)
    }
  end

  def update_config(container, flow, block, context) do
    value =
      case Expression.evaluate_block(
             block.config.choice_expression,
             context.vars,
             FlowRunner.expression_callbacks_module()
           ) do
        {:ok, val} -> val
        {:error, reason} -> reason
      end
      |> Enum.map(fn
        # Handle the specific case of a two-element list where options are time formatted
        # i.e. list("cta", NextCard, map(times_formatted_options_list, &[&1,&1]))
        [option_a, _option_b] when is_struct(option_a, Time) ->
          time_string = Time.to_string(option_a)
          [time_string, time_string]

        # For all other options, return unchanged
        option ->
          option
      end)

    language = FlowRunner.language_for_context(flow, context)

    choices_and_resources =
      Enum.map(value, fn [value, label] ->
        resource_uuid = UUID.uuid4()

        resource = %FlowRunner.Spec.Resource{
          uuid: resource_uuid,
          values: [
            %FlowRunner.Spec.ResourceValue{
              language_id: language.id,
              content_type: "TEXT",
              mime_type: "text/plain",
              modes: [context.mode],
              value: label
            }
          ]
        }

        {%{name: value, test: "block.response = #{inspect(value)}", prompt: resource_uuid},
         resource}
      end)

    exits =
      Enum.map(value, fn [value, _label] ->
        %FlowRunner.Spec.Exit{
          uuid: UUID.uuid4(),
          test: "block.value = #{inspect(value)}",
          name: value,
          default: false,
          destination_block: block.config.destination_block
        }
      end)

    # this should only be one but can also not exist, using a
    # filter here guarantees we'll always get back a list, not a `null`
    # if we attempt to find one. That allows us to just concatenate the
    # two exists lists below rather than adding conditional handling for nils
    # or empty lists
    original_default_exits = Enum.filter(block.exits, & &1.default)

    choices = Enum.map(choices_and_resources, fn {choice, _resource} -> choice end)
    resources = Enum.map(choices_and_resources, fn {_choice, resource} -> resource end)

    block = %{
      block
      | config: Map.put(block.config, :choices, choices),
        exits: exits ++ original_default_exits
    }

    flow = %{flow | blocks: [block | Enum.reject(flow.blocks, &(&1.uuid == block.uuid))]}

    container = %{
      container
      | flows: [flow | Enum.reject(container.flows, &(&1.uuid == flow.uuid))],
        resources: container.resources ++ resources
    }

    {:ok, container, flow, block, context}
  end

  @impl true
  @decorate with_span("DSL.Blocks.DynamicSelectOneResponse.evaluate_incoming")
  def evaluate_incoming(container, flow, block, context) do
    {:ok, container, flow, block, context} = update_config(container, flow, block, context)

    {:ok, container, flow, block,
     %{context | waiting_for_user_input: true, last_block_uuid: block.uuid}}
  end

  @impl true
  @decorate with_span("DSL.Blocks.DynamicSelectOneResponse.evaluate_outgoing")
  def evaluate_outgoing(container, flow, block, context, user_input) do
    matched_option =
      Enum.find(block.config.choices, fn
        %{name: _name, test: test, prompt: _prompt} ->
          case FlowRunner.evaluate_expression_block(test, %{
                 "flow" => flow,
                 "block" => %{"response" => user_input}
               }) do
            {:error, _} -> false
            result -> result
          end
      end)

    if matched_option do
      {:ok, resource} = FlowRunner.fetch_resource_by_uuid(container, matched_option.prompt)

      {:ok, resource_value} =
        FlowRunner.fetch_resource_value(resource, context.language, context.mode, flow)

      {:ok,
       %{
         "__value__" => matched_option.name,
         "name" => matched_option.name,
         "label" => resource_value.value
       }}
    else
      {:invalid, "No choice tests evaluated to true."}
    end
  end
end
