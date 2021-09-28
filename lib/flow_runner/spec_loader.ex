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
      use Vex.Struct

      @doc "Load the map or list of maps into #{unquote(mod)} structs."
      @spec load!(map) :: t()
      @spec load!([map]) :: [t()]
      def load!(list) when is_list(list) do
        list
        |> Enum.map(&load!/1)
        |> Enum.map(&validate!/1)
      end

      def load!(map) when is_map(map) do
        FlowRunner.SpecLoader.load!(unquote(mod), map, unquote(manually_loaded_fields))
      end

      @spec load(map | [map]) ::
              {:ok, t()}
              | {:ok, [t()]}
              | {:error, String.t()}
      def load(data) do
        {:ok, validate!(load!(data))}
      rescue
        error in KeyError -> {:error, "Key #{error.key} is not valid for #{unquote(mod)}}"}
        error in ArgumentError -> {:error, error.message}
        error in RuntimeError -> {:error, error.message}
      end

      @doc "Validate a #{unquote(mod)} struct using Vex.validate"
      @spec validate!(t()) :: {:ok, t()} | {:error, String.t()}
      def validate!(impl) do
        case Vex.validate(impl) do
          {:ok, impl} ->
            impl

          {:error, errors} ->
            error_string =
              errors
              |> Enum.map(fn {:error, key, _rule, error} ->
                received_value = Map.get(impl, key)
                "#{inspect(Atom.to_string(key))} #{error}, received: #{inspect(received_value)}"
              end)
              |> Enum.join(", ")

            [module_name | _ignored] =
              impl.__struct__
              |> Module.split()
              |> Enum.reverse()

            raise RuntimeError, "In #{inspect(module_name)}: #{error_string}"
        end
      end

      defoverridable(validate!: 1)
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
        %{impl | atom_key => loader.load!(value)}
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
    _error -> reraise "Unknown key #{inspect(key)}", __STACKTRACE__
  end
end
