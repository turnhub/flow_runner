defmodule FlowRunner.Spec.Block do
  @moduledoc """
  A Block is a unit of execution within a flow. It may wait for user input
  and provide content that should be rendered to the user.
  """
  use FlowRunner.SpecLoader,
    using: [
      exits: FlowRunner.Spec.Exit
    ]

  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Exit
  alias FlowRunner.Spec.Flow
  alias FlowRunner.Spec.Blocks.Message
  alias FlowRunner.Spec.Blocks.SelectOneResponse
  alias FlowRunner.Spec.Blocks.RunFlow
  alias FlowRunner.Spec.Blocks.Log

  @derive Jason.Encoder
  defstruct uuid: nil,
            name: nil,
            label: nil,
            semantic_label: nil,
            tags: [],
            vendor_metadata: %{},
            ui_metadata: %{},
            type: nil,
            config: %{},
            exits: []

  @type t :: %__MODULE__{
          uuid: String.t(),
          name: String.t(),
          label: String.t(),
          semantic_label: String.t(),
          tags: [String.t()],
          vendor_metadata: map,
          ui_metadata: map,
          type: String.t(),
          config: map,
          exits: [Exit.t()]
        }

  validates(:uuid, presence: true, uuid: [format: :default])

  @spec evaluate_user_input(%Block{}, %FlowRunner.Context{}, iodata()) ::
          {:ok, %FlowRunner.Context{}}
  def evaluate_user_input(_block, context, nil)
      when context.waiting_for_user_input == true do
    {:ok, context}
  end

  def evaluate_user_input(block, context, user_input)
      when context.waiting_for_user_input == true do
    vars =
      Map.merge(context.vars, %{
        "block" => %{"value" => user_input},
        block.name => user_input
      })

    context = %Context{context | vars: vars, waiting_for_user_input: false}
    {:ok, context}
  end

  def evaluate_user_input(_block, context, nil) do
    {:ok, context}
  end

  def evaluate_user_input(_block, _context, _user_input) do
    {:error, "unexpectedly received user input"}
  end

  def evaluate_incoming(
        flow,
        %Block{type: "MobilePrimitives.Message"} = block,
        context,
        container
      ),
      do: Message.evaluate_incoming(flow, block, context, container)

  def evaluate_incoming(
        flow,
        %Block{type: "MobilePrimitives.SelectOneResponse"} = block,
        context,
        container
      ),
      do: SelectOneResponse.evaluate_incoming(flow, block, context, container)

  def evaluate_incoming(
        flow,
        %Block{type: "Core.RunFlow"} = block,
        context,
        container
      ),
      do: RunFlow.evaluate_incoming(flow, block, context, container)

  def evaluate_incoming(
        flow,
        %Block{type: "Core.Log"} = block,
        context,
        container
      ),
      do: Log.evaluate_incoming(flow, block, context, container)

  def evaluate_incoming(
        _flow,
        %Block{type: type},
        _context,
        _container
      ),
      do: {:error, "unknown block type #{type}"}

  def evaluate_outgoing(block, %Context{} = context, flow, user_input) do
    # Process any user input we have been given.
    with {:ok, context} <-
           Block.evaluate_user_input(
             block,
             context,
             user_input
           ),
         {:ok, context, block} <-
           Block.fetch_next_block(block, flow, context) do
      {:ok, context, block}
    else
      err -> err
    end
  end

  @spec fetch_next_block(
          %Block{},
          %Flow{},
          %Context{}
        ) ::
          {:error, iodata}
          | {:ok, %FlowRunner.Context{}, %Block{}}
  def fetch_next_block(block, %Flow{} = flow, %Context{} = context) do
    {:ok, %Exit{destination_block: destination_block}} = Block.evaluate_exits(block, context)

    if destination_block == "" || destination_block == nil do
      {:ok, %Context{context | finished: true}, nil}
    else
      case Flow.fetch_block(flow, destination_block) do
        {:ok, next_block} -> {:ok, context, next_block}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @spec evaluate_exits(%FlowRunner.Spec.Block{}, %FlowRunner.Context{}) ::
          {:ok, %FlowRunner.Spec.Exit{}} | {:error, any()}
  def evaluate_exits(%Block{exits: exits}, %Context{} = context) do
    truthy_exits = Enum.filter(exits, &Exit.evaluate(&1, context))

    if length(truthy_exits) > 0 do
      {:ok, Enum.at(truthy_exits, 0)}
    else
      {:error, "no exit evaluated to true"}
    end
  end
end
