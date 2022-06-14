defmodule FlowRunner.Contract do
  @moduledoc """
  Specify the callback functions to run a Flow.
  """

  alias FlowRunner.Context
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
              var :: map()
            ) :: {:ok, Context.t()} | {:error, String.t()}

  @doc """
  next_block transitions us from one block to the next block in a flow. It requires a
  flow, a run context and optionally user input requested from the previous block.
  It returns an updated container, flow, block, and context.

  The updated context may have context.waiting_for_user_input set to true. If so the
  next call of next_block must have user_input != nil.

  If the block was a Core.RunFlow, ie. a flow called from a flow, and it's reached its end
  then return the context of the parent flow.
  """
  @callback next_block(Container.t(), Context.t(), user_input :: nil | String.t()) ::
              {:ok, Container.t(), Flow.t(), Block.t() | nil, Context.t()}
              | {:error, reason :: String.t()}

  @doc """
  If the current block is not waiting on user input then FlowRunner proceeds automatically to
  the next block with the the context of the previous block by calling this callback.

  This is where we evaluate the block we have transitioned to and return updated container, flow,
  block, and context.
  """
  @callback evaluate_next_block(Container.t(), Flow.t(), Block.t(), Context.t()) ::
              {:ok, Container.t(), Flow.t(), Block.t(), Context.t()}
              | {:end, Container.t(), Flow.t(), Block.t(), Context.t()}
              | {:error, String.t()}

  @doc """
  Retrieves a flow from a container by its given UUID. Used internally by create_context/5 to
  load the flow when creating a new context
  """
  @callback fetch_flow_by_uuid(Container.t(), flow_uuid :: String.t()) ::
              {:ok, Flow.t()} | {:error, String.t()}

  @callback evaluate_expression(String.t(), map) :: {:ok, [term]} | {:error, String.t()}
  @callback evaluate_expression_as_string!(String.t(), map) :: String.t()
  @callback evaluate_expression_block(String.t(), map) :: {:ok, [term]} | {:error, String.t()}
end
