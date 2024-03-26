defmodule FlowRunner.Spec.Blocks.NumericResponse do
  @moduledoc """
  A specialisation of a block that allows users to send numeric input.
  """
  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  @impl true
  def validate_config!(%{"prompt" => prompt} = config) do
    validated_config = %{
      prompt: prompt,
      validation_minimum: Map.get(config, "validation_minimum", nil),
      validation_maximum: Map.get(config, "validation_maximum", nil)
    }

    if Vex.valid?(
         validated_config,
         prompt: [presence: true, uuid: true],
         validation_minimum: [number: []],
         validation_maximum: [number: []]
       ) do
      validated_config
    else
      raise "invalid 'config' for MobilePrimitive.NumericResponse block, 'prompt' field is required and needs to be a UUID."
    end
  end

  def validate_config!(_) do
    raise "invalid config, 'prompt' field is required."
  end

  @impl true
  @decorate trace("FlowRunner.Blocks.NumericResponse.evaluate_incoming")
  def evaluate_incoming(container, flow, block, context) do
    {
      :ok,
      container,
      flow,
      block,
      %Context{context | waiting_for_user_input: true, last_block_uuid: block.uuid}
    }
  end

  @impl true
  @spec evaluate_outgoing(Container.t(), Flow.t(), Block.t(), Context.t(), String.t()) ::
          {:ok, integer()} | {:invalid, String.t()}
  def evaluate_outgoing(_container, _flow, block, _context, user_input) do
    case Integer.parse(user_input) do
      {value, _} ->
        cond do
          block.config.validation_minimum && value < block.config.validation_minimum ->
            {:invalid,
             "user input is less than minimum #{value} < #{block.config.validation_minimum}"}

          block.config.validation_maximum && value > block.config.validation_maximum ->
            {:invalid,
             "user input is less than maximum #{value} > #{block.config.validation_maximum}"}

          true ->
            {:ok, value}
        end

      :error ->
        {:invalid, "Expected integer user input got #{user_input}"}
    end
  end
end
