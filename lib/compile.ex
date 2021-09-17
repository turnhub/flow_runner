defmodule FlowRunner.Compile do
  @moduledoc """
  Compile converts a JSON flow into an internal representation that is able to be run.
  """
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Exit
  alias FlowRunner.Spec.Flow
  alias FlowRunner.Spec.Resource

  def schema do
    %Container{
      flows: [
        %Flow{
          blocks: [
            %Block{
              exits: [%Exit{}]
            }
          ]
        }
      ],
      resources: [
        %Resource{
          values: [
            %FlowRunner.Spec.ResourceValue{}
          ]
        }
      ]
    }
  end

  @spec compile(iodata()) :: {:ok, %Container{}}
  def compile(json) when is_binary(json) do
    {:ok, container} = Poison.decode(json, %{as: schema()})

    case FlowRunner.Spec.Validate.results(Container.validate(container)) do
      :ok -> {:ok, container}
      {:error, reason} -> {:error, reason}
      unless -> {:error, "unexpected result #{inspect(unless)}"}
    end
  end
end
