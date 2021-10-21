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

  def compile(data) when is_map(data) do
    FlowRunner.Spec.Container.load(data)
  end

  @spec compile!(binary | map) :: FlowRunner.Spec.Container.t()
  def compile!(data) do
    FlowRunner.Spec.Container.load!(data)
  end
end
