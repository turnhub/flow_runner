defmodule FlowRunner.Compile do
    alias FlowRunner.Spec.Block
    alias FlowRunner.Spec.Container
    alias FlowRunner.Spec.Exit
    alias FlowRunner.Spec.Flow

    @schema %Container{
        flows: [
            %Flow{
                blocks: [
                    %Block{
                        exits: [%Exit{}]
                    }
                ]
            }
        ]
    }

    @spec compile(iodata()) :: {:ok, Container}
    def compile(json) do
        {:ok, container} = Poison.decode(json, as: @schema)
        case Container.validate(container) do
            :ok -> {:ok, container}
            {:error, reason} -> {:error, reason}
        end
    end
end