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
      {:ok, _container, flow} ->
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
    with {:ok, container, flow} <-
           fetch_flow_by_uuid(container, context.current_flow_uuid),
         {:ok, context, current_block, next_block} <-
           find_next_block(container, flow, context, user_input) do
      cond do
        # If we have a next block, automatically evaluate it
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
    do:
      Application.get_env(
        :flow_runner,
        :expression_callbacks_module,
        Expression.V2.Callbacks.Standard
      )

  @impl FlowRunner.Contract
  def evaluate_expression(expression, context) do
    Expression.V2.Compat.evaluate!(expression, context, expression_callbacks_module())
  end

  @impl FlowRunner.Contract
  def evaluate_expression_as_string!(expression, context) do
    Expression.V2.Compat.evaluate_as_string!(expression, context, expression_callbacks_module())
  end

  @impl FlowRunner.Contract
  def evaluate_expression_block(expression, context) do
    Expression.V2.Compat.evaluate_block!(expression, context, expression_callbacks_module())
  end

  defdelegate fetch_resource_by_uuid(container, uuid), to: FlowRunner.Spec.Container

  def fetch_resource_value(resource, language, mode, flow),
    do: FlowRunner.Spec.Resource.matching_resource(resource, language, mode, flow)

  @doc """
  Get the language struct for a context

  The FlowRunner.Context stores the language as an iso-639-3 language code ("eng"/"afr" etc).
  Internally flowspec maintains a list of languages which have a UUID as an id.

  Here we lookup the language struct for the language code currently active in the context.
  This is needed because the Flowspec resource values refer to languages by the Language's ID (uuid)
  rather than the iso-639-3 code.
  """
  @spec language_for_context(FlowRunner.Spec.Flow.t(), FlowRunner.Context.t()) ::
          FlowRunner.Spec.Language.t()
  def language_for_context(flow, context),
    do:
      Enum.find(flow.languages, &(&1.iso_639_3 == context.language)) ||
        default_flow_language(flow)

  @doc """
  Get the default language for a flow.

  The flowspec is unclear about how to go about this. Our assumption is
  that the first language defined in the list of a flow's languages is
  the default language.

  The flowspec does guarantee that there must be at least 1 language.
  """
  @spec default_flow_language(FlowRunner.Spec.Flow.t()) :: FlowRunner.Spec.Language.t()
  def default_flow_language(flow), do: List.first(flow.languages)

  @doc """
  Find the next block the current context is expecting. Returns both the current block and the next
  block
  """
  @spec find_next_block(Container.t(), Flow.t(), Context.t(), user_input :: String.t() | nil) ::
          {:ok, Context.t(), previous_block :: Block.t() | nil, next_block :: Block.t() | nil}
          | {:error, reason :: String.t()}
  def find_next_block(
        %Container{} = _container,
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
        %Container{} = container,
        %Flow{} = flow,
        %Context{last_block_uuid: last_block_uuid} = context,
        user_input
      ) do
    # Fetch the previous block we were at and then evaluate the
    # exits to identify the next block.
    with {:ok, previous_block} <-
           Flow.fetch_block(flow, last_block_uuid),
         {:ok, context, next_block} <-
           Block.evaluate_outgoing(container, flow, previous_block, context, user_input) do
      {:ok, context, previous_block, next_block}
    else
      err -> err
    end
  end
end
