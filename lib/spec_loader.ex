defmodule FlowRunner.SpecLoader do
  @moduledoc """
  A macro to help loading of JSON floip specs into structs.

  Some keys need some extra help when loading, for when that is the
  case list those key names under the `manual` key.

  # Example

    defmodule FlowRunner.SomeSpecType do
      use FlowRunner.SpecLoader
    end
    defmodule FlowRunner.SomeSpecType do
      use FlowRunner.SpecLoader, manual: %{"some_field" => FlowRunner.Spec.SomeField}
    end

  """
  defmacro __using__(opts) do
    manually_loaded_fields =
      Keyword.get(
        opts,
        :manual,
        quote(do: [])
      )

    %{module: mod} = __CALLER__

    quote do
      @doc "Load the map or list of maps into #{unquote(mod)} structs."
      @spec load!(map) :: unquote(mod).t
      @spec load!([map]) :: [unquote(mod).t]
      def load!(list) when is_list(list), do: Enum.map(list, &load!/1)

      def load!(map) when is_map(map) do
        FlowRunner.SpecLoader.load!(unquote(mod), map, unquote(manually_loaded_fields))
      end

      @spec load(map | [map]) ::
              {:ok, unquote(mod).t}
              | {:ok, [unquote(mod).t]}
              | {:error, String.t()}
      def load(data) do
        {:ok, load!(data)}
      rescue
        error in KeyError -> {:error, "Key #{error.key} is not valid for #{unquote(mod)}}"}
        error in ArgumentError -> {:error, error.message}
      end
    end
  end

  def load!(mod, map, manually_loaded_fields) do
    manually_loaded_keys = Enum.map(Keyword.keys(manually_loaded_fields), &to_string/1)

    {manual_fields, auto_fields} =
      Enum.split_with(map, fn {key, _value} -> Enum.member?(manually_loaded_keys, key) end)

    impl =
      manual_fields
      |> Enum.reduce(struct(mod), fn {key, value}, impl ->
        atom_key = atom_or_argument_error(key)
        loader = Keyword.get(manually_loaded_fields, atom_key)
        %{impl | atom_key => loader.load(value)}
      end)

    auto_fields
    |> Enum.reduce(impl, fn {key, value}, impl ->
      struct_key = atom_or_argument_error(key)
      %{impl | struct_key => value}
    end)
  end

  defp atom_or_argument_error(key) do
    String.to_existing_atom(key)
  rescue
    ArgumentError -> raise ArgumentError, message: "Unknown key #{inspect(key)}"
  end
end
