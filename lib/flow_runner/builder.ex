defmodule FlowRunner.FlowBuilder do
  defmacro __using__(_opts) do
    quote do
      import FlowRunner.FlowBuilder

      @default_language "eng"
      @flows []
      @blocks []
      @resources []
      @before_compile FlowRunner.FlowBuilder
    end
  end

  defmacro default_language(language) do
    quote do
      @default_language unquote(language)
    end
  end

  defmacro flow(name, opts \\ quote(do: []), do: code_block) do
    quote do
      unquote(code_block)
      interaction_timeout = unquote(opts)[:interaction_timeout] || :timer.minutes(5)

      [first_block | remainder_blocks] = Enum.reverse(@blocks)

      flow = %{
        "uuid" => UUID.uuid4(),
        "name" => to_string(unquote(name)),
        "first_block_id" => first_block["uuid"],
        "interaction_timeout" => interaction_timeout,
        "blocks" => [first_block | remainder_blocks],
        "languages" => []
      }

      @flows [flow | @flows]
    end
  end

  defmacro block(name, do: code_block) do
    quote do
      block = unquote(code_block)
      block = Map.merge(block, %{"uuid" => UUID.uuid4(), "name" => to_string(unquote(name))})
      @blocks [block | @blocks]
    end
  end

  def prompt(prompt, choices, opts \\ []) do
    label = opts[:label] || String.downcase(prompt)

    %{
      "type" => "MobilePrimitives.SelectOneResponse",
      "label" => label,
      "config" => %{
        "prompt" => "???",
        "choices" =>
          Enum.map(choices, fn {key, _value} ->
            %{
              "name" => to_string(key),
              "test" => "block.response = \"#{to_string(key)}\"",
              "prompt" => "???"
            }
          end)
      },
      "exits" =>
        Enum.map(choices, fn {key, _value} ->
          %{
            "uuid" => UUID.uuid4(),
            "name" => "#{to_string(key)}_exit",
            "test" => "block.value = \"#{to_string(key)}\"",
            "destination_block" => block_uuid_for(key)
          }
        end)
    }
  end

  def text(text, opts \\ []) do
    label = opts[:label] || String.downcase(text)

    %{
      "type" => "MobilePrimitives.Message",
      "label" => label,
      "config" => %{
        "prompt" => "???"
      },
      "exits" => []
    }
  end

  defp block_uuid_for(_key) do
    # block = Enum.find(@flows, &(&1["name"] == to_string(key)))
    # block["uuid"]
    "???"
  end

  defmacro __before_compile__(_env) do
    quote do
      def as_floip do
        %{
          "specification_version" => "1.0.0-rc3",
          "uuid" => UUID.uuid4(),
          "flows" => @flows,
          "resources" => @resources
        }
      end
    end
  end
end
