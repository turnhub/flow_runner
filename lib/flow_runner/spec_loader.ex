defmodule FlowRunner.SpecLoader do
  @moduledoc """
  A macro to help loading of JSON floip specs into structs.

  Some keys need some extra help when loading, for when that is the
  case list those key names under the `using` key.

  # Example

    defmodule FlowRunner.SomeSpecType do
      use FlowRunner.SpecLoader
    end
    defmodule FlowRunner.SomeSpecType do
      use FlowRunner.SpecLoader, using: %{"some_field" => FlowRunner.Spec.SomeField}
    end

  """

  @callback cast!(blocks_module :: module, map | [map]) :: any | [any]
  @callback load!(blocks_module :: module, map | [map]) :: any | [any]
  @callback validate!(blocks_module :: module, any) :: any

  defmacro __using__(opts) do
    manually_loaded_fields =
      Keyword.get(
        opts,
        :using,
        quote(do: [])
      )

    %{module: mod} = __CALLER__

    quote do
      use Vex.Struct

      @behaviour FlowRunner.SpecLoader
      @doc "Load the map or list of maps into #{unquote(mod)} structs."
      @impl true
      @spec load!(module, map) :: t()
      @spec load!(module, [map]) :: [t()]
      def load!(blocks_module, list) when is_list(list) do
        list
        |> Enum.map(&load!(blocks_module, &1))
      end

      @impl true
      def load!(blocks_module, map) when is_map(map) do
        casted_map = cast!(blocks_module, map)

        implementation =
          FlowRunner.SpecLoader.load!(
            blocks_module,
            unquote(mod),
            casted_map,
            unquote(manually_loaded_fields)
          )

        validate!(blocks_module, implementation)
      end

      @doc "Cast the received fields to their internal representation"
      @impl true
      @spec cast!(module, map) :: map
      def cast!(_module, map), do: map

      @doc "Validate a #{unquote(mod)} struct using Vex.validate"
      @impl true
      @spec validate!(blocks_module :: module, t()) :: t()
      defdelegate validate!(blocks_module, impl), to: FlowRunner.SpecLoader

      defoverridable(load!: 2, validate!: 2, cast!: 2)
    end
  end

  @doc "Validate a struct using Vex.validate"
  def validate!(_blocks_module, impl) do
    case Vex.validate(impl) do
      {:ok, impl} ->
        impl

      {:error, errors} ->
        error_string =
          errors
          |> Enum.map_join(", ", fn {:error, key, _rule, error} ->
            received_value = Map.get(impl, key)
            "#{inspect(Atom.to_string(key))} #{error}, received: #{inspect(received_value)}"
          end)

        [module_name | _ignored] =
          impl.__struct__
          |> Module.split()
          |> Enum.reverse()

        raise RuntimeError, "In #{inspect(module_name)}: #{error_string}"
    end
  end

  def load!(blocks_module, mod, struct, manually_loaded_fields)
      when is_struct(struct) and is_atom(blocks_module),
      do: load!(blocks_module, mod, Map.from_struct(struct), manually_loaded_fields)

  def load!(blocks_module, mod, map, manually_loaded_fields) when is_atom(blocks_module) do
    manually_loaded_keys = Enum.map(Keyword.keys(manually_loaded_fields), &to_string/1)

    {manual_fields, auto_fields} =
      Enum.split_with(map, fn {key, _value} -> Enum.member?(manually_loaded_keys, key) end)

    impl =
      manual_fields
      |> Enum.reduce(struct(mod), fn {key, value}, impl ->
        atom_key = atom_or_argument_error(key)
        loader = Keyword.get(manually_loaded_fields, atom_key)
        %{impl | atom_key => loader.load!(blocks_module, value)}
      end)

    auto_fields
    |> Enum.reduce(impl, fn {key, value}, impl ->
      struct_key = atom_or_argument_error(key)
      %{impl | struct_key => value}
    end)
  end

  defp atom_or_argument_error(key) when is_atom(key), do: key

  defp atom_or_argument_error(key) when is_binary(key) do
    String.to_existing_atom(key)
  rescue
    _error -> reraise "Unknown key #{inspect(key)}", __STACKTRACE__
  end
end
