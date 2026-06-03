defmodule FlowRunner.Spec.Block do
  @moduledoc """
  A Block is a unit of execution within a flow. It may wait for user input
  and provide content that should be rendered to the user.
  """
  use OpenTelemetryDecorator

  use FlowRunner.SpecLoader,
    using: [
      exits: FlowRunner.Spec.Exit
    ]

  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Exit
  alias FlowRunner.Spec.Flow

  require Logger

  @doc """
  Load the raw config received from the original JSON, validate it
  and return a map with atom keys with the correct configuration
  """
  @callback validate_config!(map) :: map

  @doc """
  Evaluate the block we have transitioned to and return updated container, flow,
  block and context
  """
  @callback evaluate_incoming(Container.t(), Flow.t(), Block.t(), Context.t()) ::
              {:ok, Container.t(), Flow.t(), Block.t(), Context.t()}
              | {:error, String.t()}

  @doc """
  On leaving a block give the block an opportunity to evaluate the inputs received.
  This allows the block to fulfill tasks such as validation.

  Return one of:

    * `{:ok, user_input}` — default. The validated input is stored in
      `context.vars[block.name]` (and `context.vars["block"]["value"]`) and
      `waiting_for_user_input` is cleared. Appropriate for
      question-shaped blocks whose output _is_ the user's reply.

    * `{:ok, user_input, opts}` — same as above plus a keyword list of
      options. Supported options:

        - `preserve_vars: true` — do NOT overwrite `context.vars[block.name]`
          with the user input, but still clear `waiting_for_user_input`.
          Use this for blocks that set their own structured vars before
          pausing and must preserve that structure across the resume so
          downstream exits can read it.

    * `{:invalid, reason}` — the flow runner will exit through the
      block's default response.
  """
  @callback evaluate_outgoing(Container.t(), Flow.t(), Block.t(), Context.t(), user_input :: any) ::
              {:ok, user_input :: any}
              | {:ok, user_input :: any, opts :: Keyword.t()}
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

  def get_block(blocks_module, type), do: Map.get(blocks_module.blocks(), type)

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

  def load_config_for_set_contact_property!(%{"set_contact_property" => properties})
      when is_list(properties) do
    %{set_contact_property: Enum.map(properties, &cast_set_contact_property_entry!/1)}
  end

  def load_config_for_set_contact_property!(%{"set_contact_property" => _}) do
    raise "set_contact_property! requires 'property_key' and 'property_value' fields, " <>
            "or a list of such objects."
  end

  def load_config_for_set_contact_property!(%{}) do
    %{}
  end

  defp cast_set_contact_property_entry!(%{
         "property_key" => property_key,
         "property_value" => property_value
       }) do
    %{property_key: property_key, property_value: property_value}
  end

  defp cast_set_contact_property_entry!(other) do
    raise "set_contact_property! list entry requires 'property_key' and " <>
            "'property_value' fields, got: #{inspect(other)}"
  end

  def load_config_for_type!(blocks_module, type, config) do
    validated_config =
      if implementation = get_block(blocks_module, type) do
        implementation.validate_config!(config)
      else
        raise "unknown block type '#{type}'"
      end

    # All blocks can optionally have a set_contact_property config. Let's
    # validate that now and merge it in.
    Map.merge(validated_config, load_config_for_set_contact_property!(config))
  end

  @spec evaluate_user_input(Block.t(), Context.t(), iodata()) ::
          {:ok, Context.t()} | {:error, String.t()}
  def evaluate_user_input(block, context, user_input),
    do: evaluate_user_input(block, context, user_input, [])

  @spec evaluate_user_input(Block.t(), Context.t(), iodata(), Keyword.t()) ::
          {:ok, Context.t()} | {:error, String.t()}
  def evaluate_user_input(_block, context, nil, _opts)
      when context.waiting_for_user_input == true do
    {:ok, context}
  end

  def evaluate_user_input(block, %Context{} = context, user_input, opts)
      when context.waiting_for_user_input == true and is_list(opts) do
    if Keyword.get(opts, :preserve_vars, false) do
      {:ok, %Context{context | waiting_for_user_input: false}}
    else
      vars =
        Map.merge(context.vars, %{
          "block" => %{"value" => user_input},
          block.name => user_input
        })

      {:ok, %Context{context | vars: vars, waiting_for_user_input: false}}
    end
  end

  def evaluate_user_input(%{type: "Core.Case"} = block, %Context{} = context, user_input, _opts) do
    vars =
      Map.merge(context.vars, %{
        "block" => %{"value" => user_input},
        block.name => user_input
      })

    {:ok, %Context{context | vars: vars}}
  end

  def evaluate_user_input(_block, context, nil, _opts) do
    {:ok, context}
  end

  def evaluate_user_input(_block, _context, user_input, _opts) do
    {:error, "unexpectedly received user input: #{inspect(user_input)}"}
  end

  @decorate with_span("FlowRunner.Spec.Block.evaluate_incoming")
  def evaluate_incoming(container, flow, %Block{type: type} = block, context) do
    O11y.set_attributes(
      block_type: block.type,
      block_name: block.name,
      block_uuid: block.uuid,
      block_config: block.config
    )

    if implementation = get_block(FlowRunner.blocks_module(), type) do
      implementation.evaluate_incoming(container, flow, block, context)
    else
      {:error, "unknown block type #{type}"}
    end
  end

  @decorate with_span("FlowRunner.Spec.Block.evaluate_outgoing")
  @spec evaluate_outgoing(Container.t(), Flow.t(), Block.t(), Context.t(), user_input :: any) ::
          {:ok, Context.t(), Block.t()} | {:invalid, reason :: String.t()}
  def evaluate_outgoing(
        container,
        flow,
        %Block{type: type} = block,
        %Context{} = context,
        user_input
      ) do
    O11y.set_attributes(
      block_type: block.type,
      block_name: block.name,
      block_uuid: block.uuid,
      block_config: block.config
    )

    # Give the block an opportunity to evaluate the input. If it returns :ok,
    # we go ahead and store the user input, evaluate the exit and then move
    # onto the next block.
    # If it returns :invalid we will exit through the default block as the
    # block has failed validations.
    #
    # We will however store the supplied (invalid) input in the context as
    # that could be useful in later blocks to report back on the supplied
    # invalid or (in the case of MobilePrimitives.SelectOneResponse "unmatched") value

    block_module = get_block(FlowRunner.blocks_module(), type)

    with {:ok, user_input, opts} <-
           normalize_outgoing(
             block_module.evaluate_outgoing(container, flow, block, context, user_input)
           ),
         # Process any user input we have been given.
         {:ok, context} <- evaluate_user_input(block, context, user_input, opts),
         {:ok, context, block} <- fetch_next_block(block, flow, context) do
      {:ok, context, block}
    else
      {:invalid, reason} ->
        Logger.info("Fetching default block because #{reason}")

        {:ok, context} = evaluate_user_input(block, context, user_input)

        fetch_default_block(block, flow, context)
    end
  end

  defp normalize_outgoing({:ok, user_input}), do: {:ok, user_input, []}
  defp normalize_outgoing({:ok, user_input, opts}) when is_list(opts), do: {:ok, user_input, opts}
  defp normalize_outgoing({:invalid, _} = invalid), do: invalid

  @spec fetch_default_block(Block.t(), Flow.t(), Context.t()) ::
          {:error, String.t()} | {:ok, Context.t(), Block.t() | nil}
  def fetch_default_block(block, %Flow{} = flow, %Context{} = context) do
    case evaluate_default_exit(block) do
      {:ok, %Exit{destination_block: destination_block}}
      when is_nil(destination_block) or destination_block == "" ->
        {:ok, %Context{context | finished: true}, nil}

      {:ok, %Exit{destination_block: destination_block}} ->
        with {:ok, next_block} <- Flow.fetch_block(flow, destination_block) do
          {:ok, context, next_block}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec fetch_next_block(Block.t(), Flow.t(), Context.t()) ::
          {:error, String.t()} | {:ok, Context.t(), Block.t()}
  def fetch_next_block(block, %Flow{} = flow, %Context{} = context) do
    case evaluate_exits(block, context) do
      {:ok, %Exit{destination_block: destination_block}}
      when is_nil(destination_block) or destination_block == "" ->
        {:ok, %Context{context | finished: true}, nil}

      {:ok, %Exit{destination_block: destination_block}} ->
        with {:ok, next_block} <- Flow.fetch_block(flow, destination_block) do
          {:ok, context, next_block}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec evaluate_exits(Block.t(), Context.t()) :: {:ok, Exit.t()} | {:error, String.t()}
  @decorate with_span("FlowRunner.Spec.Block.evaluate_exits")
  def evaluate_exits(%Block{exits: exits} = block, %Context{} = context) do
    O11y.set_attributes(
      block_type: block.type,
      block_name: block.name,
      block_uuid: block.uuid,
      block_config: block.config
    )

    case exits
         |> Enum.reject(&(&1.default == true))
         |> Enum.filter(&Exit.evaluate(&1, context)) do
      [first_truthy_exit | _] -> {:ok, first_truthy_exit}
      [] -> evaluate_default_exit(block)
    end
  end

  @spec evaluate_default_exit(Block.t()) :: {:error, String.t()} | {:ok, Exit.t()}
  def evaluate_default_exit(%Block{exits: exits}) do
    case Enum.filter(exits, &(&1.default == true)) do
      [first_default_exit | _] -> {:ok, first_default_exit}
      _ -> {:error, "No default exit available"}
    end
  end
end
