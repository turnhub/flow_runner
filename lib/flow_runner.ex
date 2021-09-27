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

  """
  def start_flow(container, flow_uuid, language, mode) do
    with {:ok, _flow} <- Container.fetch_flow_by_uuid(container, flow_uuid) do
      {:ok, %Context{current_flow_uuid: flow_uuid, language: language, mode: mode}}
    else
      err -> err
    end
  end

  @doc """
  next_block transitions us from one block to the next block in a flow. It requires a
  flow, a run context and optionally user input requested from the previous block.
  It returns an updated context, optionally an output that should be rendered on the
  clients device.

  The updated context may have context.waiting_for_user_input set to true. If so the
  next call of next_block must have user_input != nil.
  """
  def next_block(container, context, user_input \\ nil)

  def next_block(
        %Container{},
        %Context{} = context,
        user_input
      )
      when context.waiting_for_user_input and user_input == nil do
    {:error, "waiting for user input but did not receive it"}
  end

  def next_block(
        %Container{} = container,
        %Context{} = context,
        user_input
      ) do
    # Identify the block we are transitioning to and then evaluate incoming block rules.
    with {:ok, flow} <- Container.fetch_flow_by_uuid(container, context.current_flow_uuid),
         {:ok, context, next_block} <- FlowRunner.find_next_block(flow, context, user_input) do
      # If we have ended a Core.RunFlow block then.
      if next_block == nil && context.parent_context != nil do
        {:ok, context.parent_context, nil}
      else
        evaluate_next_block(next_block, container, flow, context)
      end
    else
      err -> err
    end
  end

  def evaluate_next_block(nil, _container, _flow, context) do
    {:end, context}
  end

  def evaluate_next_block(next_block, container, flow, context) do
    # Evaluate the block we have transitioned to and return updated context and output.
    case Block.evaluate_incoming(flow, next_block, context, container) do
      {:ok, context, output} ->
        {:ok, context, output}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def find_next_block(%Flow{} = flow, %Context{last_block_uuid: nil} = context, _user_input) do
    # If this is the first time we are executing this flow (last_block_uuid == nil) then
    # transition to the first block.
    {:ok, next_block} = Flow.fetch_block(flow, flow.first_block_id)
    {:ok, context, next_block}
  end

  def find_next_block(
        %Flow{} = flow,
        %Context{last_block_uuid: last_block_uuid} = context,
        user_input
      ) do
    # Fetch the previous block we were at and then evaluate the
    # exits to identify the next block.
    with {:ok, previous_block} <- Flow.fetch_block(flow, last_block_uuid),
         {:ok, context, next_block} <-
           Block.evaluate_outgoing(previous_block, context, flow, user_input) do
      {:ok, context, next_block}
    else
      err -> err
    end
  end
end
