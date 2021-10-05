defmodule FlowRunner.Spec.Blocks.SetGroupMembership do
  @moduledoc """
  Set a group membership.
  """
  alias FlowRunner.Context
  alias FlowRunner.Output
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  require Logger

  def evaluate_incoming(
        %Flow{},
        %Block{config: %{"group_key" => key, "is_member" => is_member}} = block,
        %Context{} = context,
        %Container{}
      ) do
    name = Map.get(block.config, "group_name", nil)

    output = %Output{
      group_update_key: key,
      group_update_name: name,
      group_update_is_member: is_member
    }

    {:ok, %Context{context | last_block_uuid: block.uuid}, output}
  end
end
