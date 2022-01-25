defmodule FlowRunner.Blocks do
  @moduledoc """
  The default blocks as per the FLOIP spec 1.0.0-rc3
  """

  @callback blocks() :: %{(type :: String.t()) => implementation :: module}

  @doc """
  Returns the default blocks as per the FLOIP spec
  """
  @spec blocks() :: %{(type :: String.t()) => implementation :: module}
  def blocks() do
    %{
      "Core.Case" => FlowRunner.Spec.Blocks.Case,
      "Core.Log" => FlowRunner.Spec.Blocks.Log,
      "Core.Output" => FlowRunner.Spec.Blocks.Output,
      "Core.RunFlow" => FlowRunner.Spec.Blocks.RunFlow,
      "Core.SetContactProperty" => FlowRunner.Spec.Blocks.SetContactProperty,
      "Core.SetGroupMembership" => FlowRunner.Spec.Blocks.SetGroupMembership,
      "MobilePrimitives.SelectOneResponse" => FlowRunner.Spec.Blocks.SelectOneResponse,
      "MobilePrimitives.Message" => FlowRunner.Spec.Blocks.Message,
      "MobilePrimitives.NumericResponse" => FlowRunner.Spec.Blocks.NumericResponse,
      "MobilePrimitives.OpenResponse" => FlowRunner.Spec.Blocks.OpenResponse
    }
  end
end
