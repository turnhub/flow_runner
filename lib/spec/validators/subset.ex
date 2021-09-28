defmodule FlowRunner.Spec.Validators.SubsetValidator do
  use Vex.Validator

  def validate(value, options) do
    value_set = MapSet.new(value)
    options_set = MapSet.new(options)

    if MapSet.subset?(value_set, options_set) do
      :ok
    else
      {:error, "must be part of the set #{inspect(options)}"}
    end
  end
end
