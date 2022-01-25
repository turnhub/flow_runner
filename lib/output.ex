defmodule FlowRunner.Output do
  @moduledoc """
  Output is a struct that contains information that should be sent to a user.
  """
  defstruct [
    :prompt,
    :choices,
    :contact_update_key,
    :contact_update_value,
    :group_update_key,
    :group_update_name,
    :group_update_is_member,
    :block
  ]

  @type t :: %__MODULE__{
          prompt: String.t() | nil,
          choices: [{String.t(), String.t()}] | nil,
          contact_update_key: String.t() | nil,
          contact_update_value: any,
          group_update_key: String.t() | nil,
          group_update_name: String.t() | nil,
          group_update_is_member: boolean | nil,
          block: FlowRunner.Spec.Block.t() | nil
        }
end
