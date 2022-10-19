defmodule FlowRunner.Context do
  @moduledoc """
  A context provides information about an ongoing user flow session.
  """
  alias FlowRunner.Context

  @type t :: %__MODULE__{
          language: String.t(),
          mode: String.t(),
          log: [String.t()],
          waiting_for_user_input: boolean,
          waiting_for_flow: nil | String.t(),
          current_flow_uuid: nil | String.t(),
          last_block_uuid: nil | String.t(),
          vars: map,
          finished: boolean,
          parent_flow_uuid: nil | String.t(),
          parent_state_uuid: nil | String.t(),
          parent_context: nil | t
        }

  defstruct [
    # iso 639-3 language code.
    language: "eng",
    mode: "TEXT",

    # -- Current flow state

    # Output of Core.Log blocks. Used for debugging.
    log: [],
    # Whether we are blocked pending user input
    waiting_for_user_input: false,
    # In case we are waiting for a child flow to finish executing, this contains its UUID
    waiting_for_flow: nil,
    # Flow uuid that is currently being run.
    current_flow_uuid: nil,
    # Uuid of the last block executed and rendered to the user. No exits have been evaluated.
    last_block_uuid: nil,
    # vars set and mutated during the flow.
    vars: %{},
    # private context
    private: %{},
    finished: false,
    # Details of the parent flow in case this flow was executed by a parent flow with `run_stack()`
    parent_flow_uuid: nil,
    parent_state_uuid: nil,
    parent_context: nil
  ]

  @doc """
  Clone a Context by its language & mode attributes, dropping everything else.
  """
  @spec clone_empty(t) :: t
  def clone_empty(%Context{language: language, mode: mode}) do
    %Context{language: language, mode: mode}
  end

  @doc """
  Assigns a new private key and value in the context.

  Modelled after [Plug.Conn.put_private/3](https://hexdocs.pm/plug/Plug.Conn.html#put_private/3)
  """
  @spec put_private(t, atom, any) :: t
  def put_private(%Context{private: private} = context, key, value) do
    %{context | private: Map.put(private, key, value)}
  end
end
