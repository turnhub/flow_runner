defmodule FlowRunner.SpecLoader do
  @moduledoc """
  A macro to help loading of JSON floip specs into structs.

  Some keys need some extra help when loading, for when that is the
  case list those key names under the `manual` key. Setting
  `manual` to `true` means _all_ fields will be loaded manually.

  # Example

    defmodule FlowRunner.SomeSpecType do
      use FlowRunner.SpecLoader
    end
    defmodule FlowRunner.SomeSpecType do
      use FlowRunner.SpecLoader, manual: %{"some_field" => FlowRunner.Spec.SomeField}
    end

  """
  defmacro __using__(opts) do
    manually_loaded_fields = Keyword.get(opts, :manual)
    %{module: mod} = __CALLER__

    quote do
      @type spec_key :: binary
      @type spec_value :: map | list | binary | number

      @spec load(map) :: unquote(mod).t
      @spec load([map]) :: [unquote(mod).t]
      def load(list) when is_list(list), do: Enum.map(list, &load/1)

      def load(map) when is_map(map) do
        FlowRunner.SpecLoader.load(unquote(mod), map, unquote(manually_loaded_fields))
      end

      @spec load_key(unquote(mod).t, spec_key, spec_value) :: unquote(mod).t | {:error, atom}
      def load_key(impl, key, value),
        do: {:error, :not_implemented}

      defoverridable(load_key: 3)
    end
  end

  def load(mod, map, true) do
    all_keys =
      mod.__struct__
      |> Map.keys()
      |> Enum.map(&to_string/1)

    load(mod, map, all_keys)
  end

  def load(mod, map, manually_loaded_fields) do
    manually_loaded_fields = manually_loaded_fields || %{}

    {manual_fields, auto_fields} =
      Enum.split_with(map, fn {key, _value} -> Map.has_key?(manually_loaded_fields, key) end)

    impl =
      manual_fields
      |> Enum.reduce(struct(mod), fn {key, value}, impl ->
        atom_key = String.to_existing_atom(key)
        loader = Map.get(manually_loaded_fields, key)
        %{impl | atom_key => load_value(loader, value)}
      end)

    auto_fields
    |> Enum.reduce(impl, fn {key, value}, impl ->
      struct_key = String.to_existing_atom(key)
      Map.put(impl, struct_key, value)
    end)
  end

  def load_value(loader, value) when is_list(value), do: Enum.map(value, &loader.load/1)

  def load_value(loader, value) when is_map(value), do: loader.load(value)
end
