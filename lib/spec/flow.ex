defmodule FlowRunner.Spec.Flow do
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
end