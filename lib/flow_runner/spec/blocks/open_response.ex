defmodule FlowRunner.Spec.Blocks.OpenResponse do
  @moduledoc """
  A specialisation of a block that sends users a set of options and
  waits for the user to come back with one of them.
  """
  @behaviour FlowRunner.Spec.Block

  alias FlowRunner.Context
  alias FlowRunner.Output
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow
  alias FlowRunner.Spec.Resource

  @impl true
  def validate_config!(%{"prompt" => prompt} = config) do
    config = %{
      prompt: prompt,
      max_response_characters: Map.get(config, "max_response_characters", nil)
    }

    if Vex.valid?(config,
         prompt: [presence: true, uuid: true],
         max_response_characters: [number: []]
       ) do
      config
    else
      raise "invalid 'config' for MobilePrimitive.NumericResponse block, 'prompt' field is required and needs to be a UUID."
    end
  end

  def validate_config!(_) do
    raise "invalid config, 'prompt' fields required"
  end

  @impl true
  def evaluate_incoming(container, flow, block, context) do
    {:ok, resource} = Container.fetch_resource_by_uuid(container, block.config.prompt)

    case Resource.matching_resource(resource, context.language, context.mode, flow) do
      {:ok, prompt} ->
        value = FlowRunner.evaluate_expression_to_string!(prompt.value, context.vars)

        {
          :ok,
          %Context{context | waiting_for_user_input: true, last_block_uuid: block.uuid},
          %Output{
            block: block,
            prompt: %{prompt | value: value}
          }
        }

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  @spec evaluate_outgoing(Flow.t(), Block.t(), Context.t(), String.t()) ::
          {:ok, String.t()} | {:invalid, String.t()}
  def evaluate_outgoing(_flow, %Block{} = block, %Context{} = _context, user_input) do
    cond do
      block.config.max_response_characters == nil ->
        {:ok, user_input}

      String.length(user_input) >= block.config.max_response_characters ->
        {:invalid,
         "length of response too long #{String.length(user_input)} >= #{inspect(block.config.max_response_characters)}"}

      true ->
        {:ok, user_input}
    end
  end
end
