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
    :group_update_is_member
  ]
end
