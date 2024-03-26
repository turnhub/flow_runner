defmodule FlowRunner.Spec.Blocks.Message do
  @moduledoc """
  A type of block that sends a message to the user.
  """
  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Flow

  @impl true
  def validate_config!(%{"prompt" => prompt}) do
    config = %{prompt: prompt}

    if Vex.valid?(config, prompt: [presence: true, uuid: true]) do
      config
    else
      raise "invalid 'config' for MobilePrimitive.Message block, 'prompt' field is required and needs to be a UUID."
    end
  end

  def validate_config!(_) do
    raise "invalid 'config' for MobilePrimitive.Message block, 'prompt' field is required and needs to be a UUID."
  end

  @impl true
  @decorate trace("FlowRunner.Blocks.Message.evaluate_incoming")
  def evaluate_incoming(container, %Flow{} = flow, %Block{} = block, context) do
    {
      :ok,
      container,
      flow,
      block,
      %Context{context | waiting_for_user_input: false, last_block_uuid: block.uuid}
    }
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
