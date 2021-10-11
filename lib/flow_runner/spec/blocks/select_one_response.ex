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
    config = %{prompt: prompt, choices: choices}

    if Vex.valid?(config, prompt: [presence: true, uuid: true]) do
      config
    else
      raise "invalid 'config' for MobilePrimitive.SelectOneResponse block, 'prompt' field is required and needs to be a UUID."
    end
  end

  def validate_config!(_) do
    raise "invalid config, 'prompt' and 'choices' fields required"
  end

  def evaluate_incoming(flow, block, context, container) do
    {:ok, resource} = Container.fetch_resource_by_uuid(container, block.config.prompt)

    case Resource.matching_resource(resource, context.language, context.mode, flow) do
      {:ok, prompt} ->
        {:ok, value} = Expression.evaluate(prompt.value, context.vars)

        {
          :ok,
          %Context{context | waiting_for_user_input: true, last_block_uuid: block.uuid},
          %Output{
            prompt: %{value: value},
            choices: block.config.choices
          }
        }

      {:error, reason} ->
        {:error, reason}
    end
  end

  def evaluate_outgoing(_block, user_input) do
    {:ok, user_input}
  end
end
