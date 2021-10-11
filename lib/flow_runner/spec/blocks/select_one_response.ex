defmodule FlowRunner.Spec.Blocks.SelectOneResponse do
  @moduledoc """
  A specialisation of a block that sends users a set of options and
  waits for the user to come back with one of them.
  """
  alias FlowRunner.Context
  alias FlowRunner.Output
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Resource

  def validate_config!(%{"prompt" => prompt, "choices" => choices}) do
    with {:ok, choices} <- validate_choices(choices),
         {:ok, %{prompt: prompt}} <-
           Vex.validate(%{prompt: prompt}, prompt: [presence: true, uuid: true]) do
      %{prompt: prompt, choices: choices}
    else
      {:error, key, _rule, reason} ->
        raise "In #{Atom.to_string(key)}: #{reason}"
    end
  end

  def validate_config!(_) do
    raise "invalid config, 'prompt' and 'choices' fields required"
  end

  defp validate_choices(choices) do
    {valid_choices, invalid_choices} =
      choices
      |> Enum.map(&validate_choice/1)
      |> Enum.split_with(fn
        {:ok, _choice} -> true
        {:error, _reason} -> false
      end)

    valid_choices_flatted =
      valid_choices
      |> Enum.map(fn {:ok, choice} -> choice end)

    invalid_choices_flattened =
      invalid_choices
      |> Enum.flat_map(fn {:error, reasons} -> reasons end)
      |> Enum.map(fn {:error, key, _rule, reason} ->
        "#{inspect(Atom.to_string(key))} #{reason}."
      end)

    if Enum.empty?(invalid_choices_flattened) do
      {:ok, valid_choices_flatted}
    else
      {:error, :choices, nil, Enum.join(invalid_choices_flattened, "\n")}
    end
  end

  defp validate_choice(%{"name" => name, "test" => test, "prompt" => prompt}),
    do:
      Vex.validate(
        %{
          name: name,
          test: test,
          prompt: prompt
        },
        name: [presence: true],
        test: [presence: true],
        prompt: [presence: true, uuid: true]
      )

  defp validate_choice(_),
    do: {:error, :choices, nil, "\"name\", \"test\", and \"prompt\" are all required."}

  def evaluate_incoming(flow, block, context, container) do
    {:ok, resource} = Container.fetch_resource_by_uuid(container, block.config.prompt)

    case Resource.matching_resource(resource, context.language, context.mode, flow) do
      {:ok, prompt} ->
        {
          :ok,
          %Context{context | waiting_for_user_input: true, last_block_uuid: block.uuid},
          %Output{
            prompt: prompt,
            choices: block.config.choices
          }
        }

      {:error, reason} ->
        {:error, reason}
    end
  end

  def evaluate_outgoing(flow, block, user_input) do
    matched_option =
      Enum.find(block.config.choices, fn
        %{name: _name, test: test, prompt: _prompt} ->
          Expression.evaluate_block!(test, %{
            "flow" => flow,
            "block" => %{"response" => user_input}
          })
      end)

    if matched_option do
      {:ok, matched_option.name}
    else
      {:ok, user_input}
    end
  end
end
