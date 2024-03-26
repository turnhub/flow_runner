defmodule FlowRunner.Spec.Blocks.SetGroupMembership do
  @moduledoc """
  Set a group membership.
  """
  @behaviour FlowRunner.Spec.Block
  use OpenTelemetryDecorator
  alias FlowRunner.Context
  alias FlowRunner.Spec.Block
  alias FlowRunner.Spec.Container
  alias FlowRunner.Spec.Flow

  require Logger

  @impl true
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

  @impl true
  @decorate trace("FlowRunner.Blocks.SetGroupMembership.evaluate_incoming")
  def evaluate_incoming(
        %Container{} = container,
        %Flow{} = flow,
        %Block{} = block,
        %Context{} = context
      ) do
    {:ok, container, flow, block, %Context{context | last_block_uuid: block.uuid}}
  end

  @impl true
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    {:ok, user_input}
  end
end
