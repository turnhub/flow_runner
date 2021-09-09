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
    def compile(json) do
        Poison.decode(json, as: @schema)
    end
end