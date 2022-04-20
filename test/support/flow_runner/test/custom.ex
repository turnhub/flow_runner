defmodule FlowRunner.Test.Custom do
  @moduledoc false
  use FlowRunner.Custom

  @impl FlowRunner.Contract
  def fetch_flow_by_uuid(_container, "error"), do: {:error, "error fetching flow"}

  def fetch_flow_by_uuid(_container, _uuid) do
    flow = %FlowRunner.Spec.Flow{
      blocks: [],
      exit_block_id: nil,
      first_block_id: "4d73864d-f579-4c72-81ea-0a38f4195228",
      interaction_timeout: 30,
      label: "test santiago",
      languages: [
        %FlowRunner.Spec.Language{
          bcp_47: nil,
          id: "22",
          iso_639_3: "eng",
          label: "English",
          variant: nil
        }
      ],
      last_modified: "2021-09-08T13:54:27.252Z",
      name: "test santiago",
      supported_modes: ["SMS"],
      uuid: "62d0084d-e88f-48c3-ac64-7a15855f0a43",
      vendor_metadata: %{}
    }

    {:ok, flow}
  end
end
