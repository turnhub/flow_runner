defmodule FlowRunner.FlowBuilder do
  defmacro __using__(_opts) do
    quote do
      import FlowRunner.FlowBuilder

      @default_language %{
        "id" => UUID.uuid4(),
        "label" => "English",
        "iso_639_3" => "eng",
        "variant" => nil,
        "bcp_47" => nil
      }
      @current_flow nil
      @flows []
      @blocks []
      @resources []
      @translations []
      @before_compile FlowRunner.FlowBuilder
    end
  end

  defmacro name(name) do
    quote do
      @name unquote(name)
    end
  end

  defmacro description(description) do
    quote do
      @description unquote(description)
    end
  end

  defmacro default_language(code, display, opts \\ quote(do: [])) do
    quote do
      opts = unquote(opts)

      @default_language %{
        "id" => UUID.uuid4(),
        "label" => unquote(display),
        "iso_639_3" => to_string(unquote(code)),
        "variant" => opts[:variant],
        "bcp_47" => opts[:bcp_47]
      }
    end
  end

  defmacro translation(code, display, opts \\ quote(do: []), do: block) do
    quote do
      translation = unquote(block)
      opts = unquote(opts)

      language = %{
        "id" => UUID.uuid4(),
        "label" => unquote(display),
        "iso_639_3" => to_string(unquote(code)),
        "variant" => opts[:variant],
        "bcp_47" => opts[:bcp_47]
      }

      @translations [{language, translation} | @translations]
    end
  end

  defmacro flow(name, opts \\ quote(do: []), do: code_block) do
    quote do
      # this writes the @blocks list
      unquote(code_block)

      ordered_blocks = Enum.reverse(@blocks)
      [first_block | remaining_blocks] = ordered_blocks

      interaction_timeout = unquote(opts)[:timeout] || :timer.minutes(5)

      flow = %{
        "name" => to_string(unquote(name)),
        "uuid" => UUID.uuid4(),
        "first_block_id" => first_block["uuid"],
        "interaction_timeout" => interaction_timeout,
        "blocks" => ordered_blocks
      }

      @flows [flow | @flows]
      @blocks []
    end
  end

  defmacro block(name, do: code_block) do
    quote do
      {resources, block} = unquote(code_block)
      block = Map.merge(block, %{"uuid" => UUID.uuid4(), "name" => to_string(unquote(name))})

      @blocks [block | @blocks]
      @resources resources ++ @resources
    end
  end

  def resource(
        value,
        content_type \\ "TEXT",
        mime_type \\ "text/plain",
        modes \\ ["RICH_MESSAGING"]
      ) do
    %{
      "uuid" => UUID.uuid4(),
      "content_type" => content_type,
      "mime_type" => mime_type,
      "modes" => modes,
      "value" => value
    }
  end

  def prompt(prompt, choices, opts \\ []) do
    label = opts[:label] || String.downcase(prompt)
    text_resource = resource(prompt)

    choices_with_resources =
      Enum.map(choices, fn {key, value} ->
        {resource(value), key, value}
      end)

    resources_for_choices =
      Enum.map(choices_with_resources, fn {resource, _key, _value} -> resource end)

    {[text_resource | resources_for_choices],
     %{
       "type" => "MobilePrimitives.SelectOneResponse",
       "label" => label,
       "config" => %{
         "prompt" => text_resource["uuid"],
         "choices" =>
           Enum.map(choices_with_resources, fn {resource, key, _value} ->
             %{
               "name" => to_string(key),
               "test" => "block.response = \"#{to_string(key)}\"",
               "prompt" => resource["uuid"]
             }
           end)
       },
       "exits" =>
         Enum.map(choices_with_resources, fn {_resource, key, _value} ->
           %{
             "uuid" => UUID.uuid4(),
             "name" => "#{to_string(key)}_exit",
             "test" => "block.value = \"#{to_string(key)}\"",
             "destination_block" => {:block, key}
           }
         end)
     }}
  end

  def text(text, opts \\ []) do
    label = opts[:label] || String.downcase(text)
    text_resource = resource(text)

    {[text_resource],
     %{
       "type" => "MobilePrimitives.Message",
       "label" => label,
       "config" => %{
         "prompt" => text_resource["uuid"]
       },
       "exits" => []
     }}
  end

  def minutes(minutes), do: :timer.minutes(minutes)
  def seconds(seconds), do: :timer.seconds(seconds)

  defmacro __before_compile__(_env) do
    quote do
      def as_floip do
        flows =
          @flows
          |> Enum.reverse()
          |> Enum.map(fn flow ->
            Map.put(flow, "languages", languages())
          end)
          |> Enum.map(&resolve_exit_destination_blocks/1)

        resources =
          Enum.map(
            @resources,
            fn master_resource ->
              %{
                "uuid" => master_resource["uuid"],
                "values" => resource_values_for(master_resource)
              }
            end
          )

        %{
          "specification_version" => "1.0.0-rc3",
          "uuid" => UUID.uuid4(),
          "description" => @description,
          "name" => @name,
          "flows" => flows,
          "resources" => resources
        }
      end

      defp resolve_exit_destination_blocks(%{"blocks" => blocks} = flow) do
        blocks =
          Enum.map(blocks, fn %{"exits" => exits} = block ->
            exits =
              Enum.map(exits, fn %{"destination_block" => {:block, key}} = defined_exit ->
                block = Enum.find(blocks, fn block -> block["name"] == to_string(key) end)
                Map.put(defined_exit, "destination_block", block["uuid"])
              end)

            Map.put(block, "exits", exits)
          end)

        Map.put(flow, "blocks", blocks)
      end

      defp resource_values_for(%{
             "value" => value,
             "content_type" => content_type,
             "mime_type" => mime_type,
             "modes" => modes
           }) do
        master = %{
          "language_id" => to_string(@default_language["id"]),
          "content_type" => content_type,
          "mime_type" => mime_type,
          "modes" => modes,
          "value" => value
        }

        translations =
          Enum.map(@translations, fn {language, translation} ->
            %{
              "language_id" => language["id"],
              "content_type" => content_type,
              "mime_type" => mime_type,
              "modes" => modes,
              "value" => translation[value]
            }
          end)

        [master | translations]
      end

      def translate(code, text) do
        {_language, translation} =
          Enum.find(@translations, fn {language, _translation} ->
            language["iso_639_3"] == to_string(code)
          end)

        translation[text]
      end

      def languages() do
        @translations
        |> Enum.map(fn {language, _translation} -> language end)
        |> then(fn translations ->
          if @default_language do
            [@default_language] ++ translations
          else
            translations
          end
        end)
      end
    end
  end
end
