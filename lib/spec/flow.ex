defmodule FlowRunner.Spec.Flow do
  @moduledoc """
  A Flow is a set of connected blocks as defined by the Flow Spec.
  """
  defstruct [
    :uuid,
    :name,
    :label,
    :last_modified,
    :interaction_timeout,
    :vendor_metadata,
    :supported_modes,
    :first_block_id,
    :exit_block_id,
    :languages,
    :blocks
  ]

  def validate(flow) do
    [FlowRunner.Spec.Validate.validate_uuid(flow)]
  end

  def fetch_block(flow, block_uuid) do
    if flow.blocks == nil do
      {:error, "no blocks in flow"}
    else
      blocks = Enum.filter(flow.blocks, &(&1.uuid == block_uuid))

      if Enum.empty?(blocks) do
        {:error, "no block with uuid #{block_uuid} in flow #{flow.uuid}"}
      else
        {:ok, Enum.at(blocks, 0)}
      end
    end
  end
end
