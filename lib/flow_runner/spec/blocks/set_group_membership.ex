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

  def validate_config!(%{"group_key" => group_key, "is_member" => is_member} = config) do
    name = Map.get(config, "group_name", nil)

    %{
      group_key: group_key,
      group_name: name,
      is_member: is_member
    }
  end

  def validate_config!(_) do
    raise "config block for Core.SetGroupMembership requires 'group_key' and 'is_member' fields"
  end

  def evaluate_incoming(
        %Flow{},
        %Block{
          config: %{
            group_key: key,
            is_member: is_member,
            group_name: name
          }
        } = block,
        %Context{} = context,
        %Container{}
      ) do
    output = %Output{
      group_update_key: key,
      group_update_name: name,
      group_update_is_member: is_member,
      block: block
    }

    {:ok, %Context{context | last_block_uuid: block.uuid}, output}
  end

  def evaluate_outgoing(_flow, _block, user_input) do
    {:ok, user_input}
  end
end
