defmodule FlowRunner do
  @moduledoc """
  Provides functions to run a Flow.
  """

  @behaviour FlowRunner.Contract

  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow
  alias FlowRunner.Compile
  require Logger

  @doc """
  Compile takes a json flow and returns a parsed and validated flow as a tuple.
  """
  defdelegate compile(json), to: Compile
  defdelegate compile(blocks_module, json), to: Compile

  @doc """
  Compile takes a json flow and returns a parsed and validated flow.
  """
  defdelegate compile!(json), to: Compile
  defdelegate compile!(blocks_module, json), to: Compile

  @doc """
  Fetches a flow from a container with the given UUID
  """
  @impl FlowRunner.Contract
  defdelegate fetch_flow_by_uuid(container, uuid), to: Container

  @impl FlowRunner.Contract
  def create_context(container, flow_uuid, language, mode, vars \\ %{}) do
    case fetch_flow_by_uuid(container, flow_uuid) do
      {:ok, flow} ->
        {:ok,
         %Context{
           current_flow_uuid: flow.uuid,
           language: language,
           mode: mode,
           vars: vars
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl FlowRunner.Contract
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
    with {:ok, flow} <- fetch_flow_by_uuid(container, context.current_flow_uuid),
         {:ok, context, current_block, next_block} <- find_next_block(flow, context, user_input) do
      cond do
        # If we have ended a Core.RunFlow block then continue where ever the parent left off
        is_nil(next_block) && not is_nil(context.parent_context) ->
          # swap parent & child contexts
          {parent_context, child_context} = Map.pop(context, :parent_context)

          {:ok, parent_flow} = fetch_flow_by_uuid(container, parent_context.current_flow_uuid)
          {:ok, parent_block} = Flow.fetch_block(parent_flow, parent_context.last_block_uuid)

          parent_context_vars =
            Map.put(parent_context.vars, parent_block.name, child_context.vars)

          {:ok, context, _current_block, next_block} =
            find_next_block(parent_flow, %{parent_context | vars: parent_context_vars}, nil)

          evaluate_next_block(container, parent_flow, next_block, context)

        # If we have a next block, automatically evaluate it as we're not waiting for user input
        # which is guarded against explicitly above
        not is_nil(next_block) ->
          evaluate_next_block(container, flow, next_block, context)

        # if we don't have a next block then we've reached our end
        is_nil(next_block) ->
          {:end, container, flow, current_block, context}
      end
    end
  end

  @impl FlowRunner.Contract
  def evaluate_next_block(container, flow, next_block, context) do
    Block.evaluate_incoming(container, flow, next_block, context)
  end

  def blocks_module(),
    do: Application.get_env(:flow_runner, :blocks_module) || FlowRunner.Blocks

  def expression_callbacks_module(),
    do: Application.get_env(:flow_runner, :expression_callbacks_module, Expression.Callbacks)

  @impl FlowRunner.Contract
  def evaluate_expression(expression, context) do
    Expression.evaluate(expression, context, expression_callbacks_module())
  end

  @impl FlowRunner.Contract
  def evaluate_expression_as_string!(expression, context) do
    Expression.evaluate_as_string!(expression, context, expression_callbacks_module())
  end

  @impl FlowRunner.Contract
  def evaluate_expression_block(expression, context) do
    Expression.evaluate_block(expression, context, expression_callbacks_module())
  end

  defdelegate fetch_resource_by_uuid(container, uuid), to: FlowRunner.Spec.Container

  def fetch_resource_value(resource, language, mode, flow),
    do: FlowRunner.Spec.Resource.matching_resource(resource, language, mode, flow)

  @doc """
  Find the next block the current context is expecting. Returns both the current block and the next
  block
  """
  @spec find_next_block(Flow.t(), Context.t(), user_input :: String.t() | nil) ::
          {:ok, Context.t(), previous_block :: Block.t() | nil, next_block :: Block.t() | nil}
          | {:error, reason :: String.t()}
  def find_next_block(
        %Flow{} = flow,
        %Context{last_block_uuid: nil} = context,
        _user_input
      ) do
    # If this is the first time we are executing this flow (last_block_uuid == nil) then
    # transition to the first block.
    {:ok, next_block} = Flow.fetch_block(flow, flow.first_block_id)
    {:ok, context, nil, next_block}
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
           Block.evaluate_outgoing(flow, previous_block, context, user_input) do
      {:ok, context, previous_block, next_block}
    else
      err -> err
    end
  end
end
