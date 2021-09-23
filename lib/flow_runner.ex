defmodule FlowRunner do
  @moduledoc """
  Provides methods to run a Flow.
  """
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  @doc """
  Compile takes a json flow and returns a parsed and validated
  flow.
  """
  defdelegate compile(json), to: FlowRunner.Compile

  @doc """
  next_block transitions us from one block to the next block in a flow. It requires a
  flow, a run context and optionally user input requested from the previous block.
  It returns an updated context, optionally an output that should be rendered on the
  clients device.

  The updated context may have context.waiting_for_user_input set to true. If so the
  next call of next_block must have user_input != nil.
  """
  def next_block(_container, _flow, _context, user_input \\ nil)

  def next_block(
        %Container{},
        %Flow{},
        %Context{} = context,
        user_input
      )
      when context.waiting_for_user_input and user_input == nil do
    {:error, "waiting for user input but did not receive it"}
  end

  def next_block(
        %Container{},
        %Flow{uuid: uuid},
        %Context{current_flow_uuid: current_flow_uuid},
        _user_input
      )
      when current_flow_uuid != nil and uuid != current_flow_uuid do
    {:error,
     "currently executing flow #{current_flow_uuid} does not match passed in flow #{uuid}"}
  end

  def next_block(
        %Container{} = container,
        %Flow{} = flow,
        %Context{} = context,
        user_input
      ) do
    # Identify the block we are transitioning to.
    {context, next_block} =
      if context.last_block_uuid == nil do
        # If this is the first time we are executing this flow then
        # transition to the first block.
        {:ok, next_block} = Flow.fetch_block(flow, flow.first_block_id)
        {context, next_block}
      else
        # Fetch the previous block we were at and then evaluate the
        # exits to identify the next block.
        {:ok, previous_block} = Flow.fetch_block(flow, context.last_block_uuid)

        {:ok, context, next_block} =
          Block.evaluate_outgoing(previous_block, context, flow, user_input)

        {context, next_block}
      end

    if next_block == nil do
      {:end, context}
    else
      # Evaluate the block we have transitioned to and return updated context and output.
      {:ok, context, output} = Block.evaluate_incoming(next_block, flow, context, container)
      context = %Context{context | last_block_uuid: next_block.uuid}
      {:ok, context, output}
    end
  end
end
