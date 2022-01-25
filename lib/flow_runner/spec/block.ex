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
  alias FlowRunner.Output
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Exit
  alias FlowRunner.Spec.Flow

  require Logger

  @callback evaluate_incoming(Container.t(), Flow.t(), Block.t(), Context.t()) ::
              {:ok, Context.t(), Output.t()}
              | {:error, String.t()}

  @callback evaluate_outgoing(Flow.t(), Block.t(), user_input :: any) ::
              {:ok, user_input :: any}
              | {:invalid, reason :: String.t()}

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
  validates(:type, presence: true)

  def get_block(blocks_module, type), do: Map.get(blocks_module.blocks, type)

  @impl true
  def cast!(blocks_module, %{"type" => type} = map) do
    config = Map.get(map, "config", %{})
    Map.put(map, "config", load_config_for_type!(blocks_module, type, config))
  end

  @impl true
  def cast!(_blocks_module, map), do: map

  @impl true
  def validate!(blocks_module, impl) do
    impl = super(blocks_module, impl)

    default_exits =
      impl.exits
      |> Enum.filter(&(&1.default == true))
      |> Enum.map(&"#{inspect(&1.name)}")

    if Enum.count(default_exits) > 1 do
      raise RuntimeError,
            "Blocks can only have 1 default exit, found: #{Enum.join(default_exits, ", ")}"
    end

    impl
  end

  def load_config_for_set_contact_property!(%{
        "set_contact_property" => %{
          "property_key" => property_key,
          "property_value" => property_value
        }
      }) do
    %{set_contact_property: %{property_key: property_key, property_value: property_value}}
  end

  def load_config_for_set_contact_property!(%{
        "set_contact_property" => _
      }) do
    raise "set_contact_property! requires 'property_key' and 'property_value' fields."
  end

  def load_config_for_set_contact_property!(%{}) do
    %{}
  end

  def load_config_for_type!(blocks_module, type, config) do
    validated_config =
      if implementation = get_block(blocks_module, type) do
        apply(implementation, :validate_config!, [config])
      else
        raise("unknown block type '#{type}'")
      end

    # All blocks can optionally have a set_contact_property config. Let's
    # validate that now and merge it in.
    Map.merge(validated_config, load_config_for_set_contact_property!(config))
  end

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

  def evaluate_contact_properties(%Block{
        config: %{
          set_contact_property: %{
            property_key: property_key,
            property_value: property_value
          }
        }
      }) do
    %{
      contact_update_key: property_key,
      contact_update_value: property_value
    }
  end

  def evaluate_contact_properties(_block) do
    %{}
  end

  def evaluate_incoming(container, flow, %Block{type: type} = block, context) do
    if implementation = get_block(container.blocks_module, type) do
      implementation.evaluate_incoming(container, flow, block, context)
    else
      {:error, "unknown block type #{type}"}
    end
  end

  def evaluate_outgoing(
        container,
        flow,
        %Block{type: type} = block,
        %Context{} = context,
        user_input
      ) do
    # Give the block an opportunity to evaluate the input. If it returns :ok,
    # we go ahead and store the user input, evaluate the exit and then move
    # onto the next block.
    # If it returns :invalid we will exit through the default block as the
    # block has failed validations.

    block_module = get_block(container.blocks_module, type)

    with {:ok, user_input} <-
           apply(block_module, :evaluate_outgoing, [flow, block, user_input]),
         # Process any user input we have been given.
         {:ok, context} <-
           Block.evaluate_user_input(
             block,
             context,
             user_input
           ),
         {:ok, context, block} <-
           Block.fetch_next_block(block, flow, context) do
      {:ok, context, block}
    else
      {:invalid, reason} ->
        Logger.info("Fetching default block because #{reason}")
        Block.fetch_default_block(block, flow, context)

      err ->
        err
    end
  end

  def fetch_default_block(block, %Flow{} = flow, %Context{} = context) do
    {:ok, %Exit{destination_block: destination_block}} =
      Block.evaluate_default_exit(block, context)

    if destination_block == "" || destination_block == nil do
      {:ok, %Context{context | finished: true}, nil}
    else
      case Flow.fetch_block(flow, destination_block) do
        {:ok, next_block} -> {:ok, context, next_block}
        {:error, reason} -> {:error, reason}
      end
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
  def evaluate_exits(%Block{exits: exits} = block, %Context{} = context) do
    truthy_exits =
      exits
      |> Enum.reject(&(&1.default == true))
      |> Enum.filter(&Exit.evaluate(&1, context))

    if length(truthy_exits) > 0 do
      {:ok, Enum.at(truthy_exits, 0)}
    else
      evaluate_default_exit(block, context)
    end
  end

  @spec evaluate_default_exit(%FlowRunner.Spec.Block{}, %FlowRunner.Context{}) ::
          {:error, String.t()} | {:ok, %FlowRunner.Spec.Exit{}}
  def evaluate_default_exit(%Block{exits: exits}, %Context{} = _context) do
    case Enum.filter(exits, &(&1.default == true)) do
      [first_default_exit | _] -> {:ok, first_default_exit}
      _ -> {:error, "No default exit available"}
    end
  end
end
