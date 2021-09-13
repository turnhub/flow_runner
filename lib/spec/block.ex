defmodule FlowRunner.Spec.Block do
  @moduledoc """
  A Block is a unit of execution within a flow. It may wait for user input
  and provide content that should be rendered to the user.
  """
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Exit
  alias FlowRunner.Spec.Flow
  alias FlowRunner.Spec.Validate

  @derive [Poison.Encoder]
  defstruct [
    :uuid,
    :name,
    :label,
    :semantic_label,
    :tags,
    :vendor_metadata,
    :ui_metadata,
    :type,
    :config,
    :exits
  ]

  def validate(block) do
    exits =
      if block.exits != nil do
        block.exits
      else
        []
      end

    [
      Validate.validate_uuid(block)
    ] ++ Enum.concat(Enum.map(exits, &Exit.validate/1))
  end

  @spec evaluate_user_input(%Block{}, %FlowRunner.Context{}, iodata()) ::
          {:ok, %FlowRunner.Context{}}
  def evaluate_user_input(block, context, user_input) do
    # TODO set the thing that needs setting.
    vars =
      Map.merge(context.vars, %{
        "block" => %{"value" => user_input},
        block.name => user_input
      })

    context = %Context{context | vars: vars, waiting_for_user_input: false}
    {:ok, context}
  end

  def evaluate_incoming(block, flow, context, container) do
    # TODO There has to be a better way to do this branch...
    case block.type do
      "MobilePrimitives.Message" ->
        FlowRunner.Spec.Blocks.Message.evaluate_incoming(flow, block, context, container)

      "MobilePrimitives.SelectOneResponse" ->
        FlowRunner.Spec.Blocks.SelectOneResponse.evaluate_incoming(
          flow,
          block,
          context,
          container
        )

      unknown ->
        {:error, "unknown block type #{unknown}"}
    end
  end

  def evaluate_outgoing(block, context, flow, user_input) do
    # Process any user input we have been given.
    context =
      if user_input != nil do
        {:ok, context} = Block.evaluate_user_input(block, context, user_input)
        context
      else
        context
      end

    {:ok, exit} = Block.evaluate_exits(block, context)
    {:ok, next_block} = Flow.fetch_block(flow, exit.destination_block)
    {context, next_block}
  end

  @spec evaluate_exits(%FlowRunner.Spec.Block{}, %FlowRunner.Context{}) ::
          {:ok, %FlowRunner.Spec.Exit{}} | {:error, any()}
  def evaluate_exits(block, %Context{} = context) do
    truthy_exits = Enum.filter(block.exits, &Exit.evaluate(&1, context))

    if length(truthy_exits) > 0 do
      {:ok, Enum.at(truthy_exits, 0)}
    else
      {:error, "no exit evaluated to true"}
    end
  end
end
