defmodule FlowRunner do

  alias FlowRunner.Context
  alias FlowRunner.Flow

  @doc """
  Compile takes a json flow and returns a parsed and validated
  flow.
  """
  def compile(_json) do
    {:error, "unimplemented :("}
  end

  def run(%Flow{} = _flow, %Context{} = _context) do
    {:error, "unimplemented :("}
  end
end
