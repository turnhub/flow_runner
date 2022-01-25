defmodule FlowRunner do
  @moduledoc """
  Provides methods to run a Flow.
  """
  alias FlowRunner.Context
  alias FlowRunner.Output
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  @doc """
  Create a fresh context for a flow.

  It takes a flow_uuid rather than a %Flow{} because blocks always refer to
  the next block by the UUID which should then be retrieved from the container.
  """
  @callback create_context(
              Container.t(),
              flow_uuid :: String.t(),
              language :: String.t(),
              mode :: String.t(),
              var :: map
            ) :: {:ok, FlowRunner.Context.t()} | {:error, String.t()}

  @doc """
  next_block transitions us from one block to the next block in a flow. It requires a
  flow, a run context and optionally user input requested from the previous block.
  It returns an updated context, optionally an output that should be rendered on the
  clients device.

  The updated context may have context.waiting_for_user_input set to true. If so the
  next call of next_block must have user_input != nil.

  If the block was a Core.RunFlow, ie. a flow called from a flow, and it's reached its end
  then return the context of the parent flow.
  """
  @callback next_block(Container.t(), Context.t(), user_input :: nil | String.t()) ::
              {:ok, %FlowRunner.Context{}, %FlowRunner.Spec.Block{} | nil,
               %FlowRunner.Output{} | nil}
              | {:error, reason :: String.t()}

  @doc """
  If the current block is not waiting on user input then FlowRunner proceeds automatically to
  the next block with the the context of the previous block by calling this callback.

  This is where we evaluate the block we have transitioned to and return updated context and output.
  """
  @callback evaluate_next_block(Container.t(), Flow.t(), Block.t(), Context.t()) ::
              {:ok, Context.t(), Block.t(), Output.t()}
              | {:end, Context.t()}
              | {:error, String.t()}

  @doc """
  Retrieves a flow from a container by its given UUID. Used internally by create_context/5 to
  load the flow when creating a new context
  """
  @callback fetch_flow_by_uuid(Container.t(), flow_uuid :: String.t()) ::
              {:ok, Flow.t()} | {:error, String.t()}

  @doc """
  Compile takes a json flow and returns a parsed and validated flow as a tuple.
  """
  defdelegate compile(json), to: FlowRunner.Compile
  defdelegate compile(blocks_module, json), to: FlowRunner.Compile

  @doc """
  Compile takes a json flow and returns a parsed and validated flow.
  """
  defdelegate compile!(json), to: FlowRunner.Compile
  defdelegate compile!(blocks_module, json), to: FlowRunner.Compile

  @doc """
  Fetches a flow from a container with the given UUID
  """
  defdelegate fetch_flow_by_uuid(container, uuid), to: FlowRunner.Spec.Container

  @spec create_context(
          Container.t(),
          flow_uuid :: String.t(),
          language :: String.t(),
          mode :: String.t(),
          vars :: map
        ) ::
          {:ok, Context.t()} | {:error, reason :: String.t()}
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

  @spec next_block(
          Container.t(),
          Context.t(),
          any
        ) ::
          {:ok, Context.t(), Block.t() | nil, Output.t() | nil}
          | {:end, Context.t()}
          | {:error, String.t()}
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
         {:ok, context, next_block} <- find_next_block(container, flow, context, user_input) do
      cond do
        # If we have ended a Core.RunFlow block then replace the context with its parent.
        is_nil(next_block) && not is_nil(context.parent_context) ->
          {:ok, context.parent_context, nil, nil}

        # If we have a next block, automatically evaluate it as we're not waiting for user input
        # which is guarded against explicitly above
        not is_nil(next_block) ->
          evaluate_next_block(container, flow, next_block, context)

        # if we don't have a next block then we've reached our end
        is_nil(next_block) ->
          {:end, context}
      end
    end
  end

  @spec evaluate_next_block(Container.t(), Flow.t(), Block.t(), Context.t()) ::
          {:ok, Context.t(), Block.t(), Output.t()} | {:error, String.t()}
  def evaluate_next_block(container, flow, next_block, context) do
    # Evaluate the block we have transitioned to and return updated context and output.
    contact_output = Block.evaluate_contact_properties(next_block)

    case Block.evaluate_incoming(container, flow, next_block, context) do
      {:ok, context, output} ->
        {:ok, context, next_block, Map.merge(output, contact_output)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def find_next_block(
        _container,
        %Flow{} = flow,
        %Context{last_block_uuid: nil} = context,
        _user_input
      ) do
    # If this is the first time we are executing this flow (last_block_uuid == nil) then
    # transition to the first block.
    {:ok, next_block} = Flow.fetch_block(flow, flow.first_block_id)
    {:ok, context, next_block}
  end

  def find_next_block(
        container,
        %Flow{} = flow,
        %Context{last_block_uuid: last_block_uuid} = context,
        user_input
      ) do
    # Fetch the previous block we were at and then evaluate the
    # exits to identify the next block.
    with {:ok, previous_block} <- Flow.fetch_block(flow, last_block_uuid),
         {:ok, context, next_block} <-
           Block.evaluate_outgoing(container, flow, previous_block, context, user_input) do
      {:ok, context, next_block}
    else
      err -> err
    end
  end
end
