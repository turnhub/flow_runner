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
  flow as a tuple.
  """
  defdelegate compile(json), to: FlowRunner.Compile

  @doc """
  Compile takes a json flow and returns a parsed and validated
  flow.
  """
  defdelegate compile!(json), to: FlowRunner.Compile

  @doc """
  """
  defdelegate fetch_flow_by_uuid(container, uuid), to: FlowRunner.Spec.Container

  @doc """
  Create a fresh context for a flow
  """
  @spec create_context(
          Container.t(),
          flow_uuid :: String.t(),
          language :: String.t(),
          mode :: String.t(),
          vars :: map
        ) ::
          {:ok, Context.t()} | {:error, reason :: String.t()}
  def create_context(container, flow_uuid, language, mode, vars \\ %{}) do
    case Container.fetch_flow_by_uuid(container, flow_uuid) do
      {:ok, _flow} ->
        {:ok,
         %Context{
           current_flow_uuid: flow_uuid,
           language: language,
           mode: mode,
           vars: vars
         }}

      err ->
        err
    end
  end

  @spec next_block(FlowRunner.Spec.Container.t(), %FlowRunner.Context{}, any) ::
          {:end, any}
          | {:error, any}
          | {:ok, %FlowRunner.Context{}, %FlowRunner.Spec.Block{},
             nil
             | %FlowRunner.Output{}}
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
      # If we have ended a Core.RunFlow block then replace the context with its parent.
      if next_block == nil && context.parent_context != nil do
        {:ok, context.parent_context, nil, nil}
      else
        evaluate_next_block(next_block, container, flow, context)
      end
    else
      err -> err
    end
  end

  @spec evaluate_next_block(nil | FlowRunner.Spec.Block.t(), any, any, any) ::
          {:end, any}
          | {:error, <<_::64, _::_*8>>}
          | {:ok, atom | map, %FlowRunner.Output{}}
  def evaluate_next_block(nil, _container, _flow, context) do
    {:end, context}
  end

  def evaluate_next_block(next_block, container, flow, context) do
    # Evaluate the block we have transitioned to and return updated context and output.
    contact_output = Block.evaluate_contact_properties(next_block)

    case Block.evaluate_incoming(flow, next_block, context, container) do
      {:ok, context, output} ->
        {:ok, context, next_block, Map.merge(output, contact_output)}

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
