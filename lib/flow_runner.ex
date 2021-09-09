defmodule FlowRunner do

  alias FlowRunner.Context
  alias FlowRunner.Spec.Container

  @doc """
  Compile takes a json flow and returns a parsed and validated
  flow.
  """
  @spec compile(String.t()) :: 
    {:ok, Container}
    | {:error, Exception.t()}
  def compile(json) do
    FlowRunner.Compile.compile(json)
  end

  def run(%Container{} = _container, %Context{} = _context) do
    {:error, "unimplemented :("}
  end
end
