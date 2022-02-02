defmodule FlowRunner.Compile do
  @moduledoc """
  Compile converts a JSON flow into an internal representation that is able to be run.
  """

  @spec compile(binary | map) ::
          {:ok, FlowRunner.Spec.Container.t()}
          | {:error, String.t()}
  def compile(json) when is_binary(json) do
    {:ok, data} = Jason.decode(json)
    compile(data)
  end

  def compile(data), do: compile(FlowRunner.blocks_module(), data)

  @spec compile(module, map) :: {:ok, FlowRunner.Spec.Container.t()} | {:error, String.t()}
  def compile(module, data) when is_map(data) do
    {:ok, compile!(module, data)}
  rescue
    error in RuntimeError -> {:error, error.message}
  end

  @spec compile!(binary | map) :: FlowRunner.Spec.Container.t()
  def compile!(data), do: compile!(FlowRunner.blocks_module(), data)

  @spec compile!(module, binary | map) :: FlowRunner.Spec.Container.t()
  def compile!(module, data) do
    FlowRunner.Spec.Container.load!(module, data)
  end
end
