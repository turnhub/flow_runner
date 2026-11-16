defmodule FlowRunner.Spec.Blocks.Case do
  @moduledoc """
  Switch between various exit conditions.

  This is an internal block used for routing logic. Users don't call it directly
  in the DSL - it's generated from `when` conditions and `then` statements.

  The chosen exit's name is evaluated as an expression and stored as the
  block's value, which is how a `variable = expression` assignment works.
  Routing exits are named with plain labels that don't parse as expressions,
  so a parse error falls back to storing the name itself.

  An expression that parses but fails while evaluating (for example comparing
  a contact field that was never written against a date) is different: under
  expression v2 semantics it also falls back to the name, which hands the
  journey the expression's own source text as the value. Under expression v3
  semantics the error is raised instead, so the journey fails visibly rather
  than carrying on with a wrong value.
  """
  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator

  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  require Logger

  @impl true
  def validate_config!(_) do
    %{}
  end

  @impl FlowRunner.Spec.Block
  @decorate with_span("FlowRunner.Case.Log.evaluate_incoming")
  def evaluate_incoming(
        %Container{} = container,
        %Flow{} = flow,
        %Block{} = block,
        %Context{} = context
      ) do
    {:ok, container, flow, block, %Context{context | last_block_uuid: block.uuid}}
  end

  @impl FlowRunner.Spec.Block
  def evaluate_outgoing(_container, _flow, block, context, nil) do
    with {:ok, block_exit} <- Block.evaluate_exits(block, context) do
      case FlowRunner.evaluate_expression_block(block_exit.name, context) do
        # The name isn't an expression (a routing label), store it as is
        {:error, :parse, _message} ->
          {:ok, block_exit.name}

        {:error, type, message} ->
          handle_evaluation_error(block_exit.name, type, message, context)

        # We managed to evaluate it and it returned nil
        nil ->
          {:ok, block_exit.name}

        value ->
          {:ok, value}
      end
    end
  end

  @spec handle_evaluation_error(String.t(), atom(), String.t(), Context.t()) ::
          {:ok, String.t()} | no_return()
  defp handle_evaluation_error(expression, type, message, %Context{private: private}) do
    case private[:expression_mode] do
      :v3 ->
        raise Expression.Error, type: type, message: message, expression: expression

      _v2_or_nil ->
        {:ok, expression}
    end
  end
end
