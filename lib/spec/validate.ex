defmodule FlowRunner.Spec.Validate do
  @moduledoc """
  Provides methods to validate Flow content.
  """
  def results(validations) do
    errors = Enum.filter(validations, &(&1 != :ok))

    if length(errors) > 0 do
      Enum.at(errors, 0)
    else
      :ok
    end
  end

  def validate_uuid(%{uuid: nil}) do
    {:error, "uuid is required"}
  end

  def validate_uuid(%{uuid: uuid}) do
    if String.match?(uuid, ~r([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})) do
      :ok
    else
      {:error, "invalid uuid '#{uuid}'"}
    end
  end
end
