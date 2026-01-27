defmodule FlowRunner.CustomBlocks.Wait do
  @moduledoc """
  A Wait block type to introduce delays in Journey flows.

  This block allows introducing delays in Journey flows to control timing
  between actions.

  ## Configuration

  The block expects the following configuration:
  - `seconds`: The number of seconds to wait (supports expressions)

  ## Example Usage

  ```
  card MyCard do
    wait(1)  # Wait for 1 second
    text("This message appears after the delay")
  end
  ```
  """

  @behaviour FlowRunner.Spec.Block
  use FlowRunner.BlockAutodoc

  @block_category "control"
  @block_doc type: "Io.Turn.Wait",
             dsl_name: "wait()",
             description:
               "Introduces a delay in the journey flow to control timing between actions.",
             config: %{
               "seconds" => %{
                 type: "integer | expression",
                 required: true,
                 description: "Number of seconds to wait (supports expressions)"
               }
             },
             example: """
             card DelayCard do
               text("Starting delay...")
               wait(2)
               text("Delay completed!")
             end
             """

  @impl FlowRunner.Spec.Block
  def validate_config!(%{"seconds" => seconds}) when is_integer(seconds) or is_binary(seconds) do
    %{seconds: seconds}
  end

  def validate_config!(config) do
    raise ArgumentError, """
    Invalid Wait block configuration: #{inspect(config)}

    Expected configuration:
    %{
      "seconds" => "5"  # String containing seconds to wait
    }
    """
  end

  @impl FlowRunner.Spec.Block
  def evaluate_incoming(container, flow, block, context) do
    # Wait blocks don't process incoming data, they just pass through
    {:ok, container, flow, block, %{context | last_block_uuid: block.uuid}}
  end

  @impl FlowRunner.Spec.Block
  def evaluate_outgoing(_container, _flow, _block, _context, user_input) do
    # Wait blocks don't process outgoing data, they just pass through
    {:ok, user_input}
  end
end
