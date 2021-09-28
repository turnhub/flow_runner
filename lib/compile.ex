defmodule FlowRunner.Compile do
  @moduledoc """
  Compile converts a JSON flow into an internal representation that is able to be run.
  """

  @spec compile(binary) ::
          {:ok, FlowRunner.Spec.Container.t()}
          | {:error, String.t()}
  def compile(json) when is_binary(json) do
    {:ok, data} = Jason.decode(json)
    FlowRunner.Spec.Container.load(data)
  end
end
