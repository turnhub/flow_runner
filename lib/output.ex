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

  @doc """
  Merges outputs into a single output.

  Note that any fields with `nil` values from output2 are rejected
  before attempting to merge in. Only non-nil values will be merged in.
  """
  @spec merge(t, t) :: t
  def merge(output1, output2)
      when is_struct(output1, __MODULE__) and is_struct(output2, __MODULE__) do
    output1_fields = Map.from_struct(output1)

    output2_fields =
      output2
      |> Map.from_struct()
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Enum.into(%{})

    struct(__MODULE__, Map.merge(output1_fields, output2_fields))
  end
end
