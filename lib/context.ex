defmodule FlowRunner.Context do
    defstruct [
        # iso 639-3 language code.
        language: "eng",
        mode: "TEXT",
        contact: nil,

        # -- Current flow state

        # Whether we are blocked pending user input
        waiting_for_user_input: false,
        # Flow uuid that is currently being run.
        current_flow_uuid: nil,
        # Uuid of the last block executed and rendered to the user. No exits have been evaluated.
        last_block_uuid: nil,
        # vars set and mutated during the flow.
        vars: %{}
    ]
end