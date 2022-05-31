defmodule FlowRunner.Spec.Blocks.Message do
  @moduledoc """
  A type of block that sends a message to the user.
  """
  @behaviour FlowRunner.Spec.Block

  alias FlowRunner.Context
  # alias FlowRunner.Output
  alias FlowRunner.Spec.Block
  # alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow
  # alias FlowRunner.Spec.Resource

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
  def evaluate_incoming(container, %Flow{} = flow, %Block{} = block, context) do
    # {:ok, resource} = Container.fetch_resource_by_uuid(container, block.config.prompt)

    # case Resource.matching_resource(resource, context.language, context.mode, flow) do
    # {:ok, prompt} ->
    # value = FlowRunner.evaluate_expression_as_string!(prompt.value, context.vars)

    {
      :ok,
      container,
      flow,
      block,
      %Context{context | waiting_for_user_input: false, last_block_uuid: block.uuid}
    }

    # {:error, reason} ->
    #   {:error, reason}
    # end
  end

  @impl true
  def evaluate_outgoing(_flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
