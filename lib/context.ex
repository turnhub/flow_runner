defmodule FlowRunner.Context do
  @moduledoc """
  A context provides information about an ongoing user flow session.
  """
  alias FlowRunner.Context

  defstruct [
    # iso 639-3 language code.
    language: "eng",
    mode: "TEXT",

    # -- Current flow state

    # Output of Core.Log blocks. Used for debugging.
    log: [],
    # Whether we are blocked pending user input
    waiting_for_user_input: false,
    # Flow uuid that is currently being run.
    current_flow_uuid: nil,
    # Uuid of the last block executed and rendered to the user. No exits have been evaluated.
    last_block_uuid: nil,
    # vars set and mutated during the flow.
    vars: %{},
    finished: false,
    # If parent_context is not nil then we should return to parent context
    # after we finish. (Part of Core.RunFlow)
    parent_context: nil
  ]

  def clone_empty(%Context{language: language, mode: mode}) do
    %Context{language: language, mode: mode}
  end
end
