defmodule FlowRunner.Blocks do
  @moduledoc """
  The default blocks as per the FLOIP spec 1.0.0-rc4
  """

  @callback blocks() :: %{(type :: String.t()) => implementation :: module}

  @doc """
  Returns the default blocks as per the FLOIP spec
  """
  @spec blocks :: %{(type :: String.t()) => implementation :: module}
  def blocks do
    %{
      "Core.Case" => FlowRunner.Spec.Blocks.Case,
      "Core.Log" => FlowRunner.Spec.Blocks.Log,
      "Core.Output" => FlowRunner.Spec.Blocks.Output,
      "Core.RunFlow" => FlowRunner.Spec.Blocks.RunFlow,
      "Core.SetContactProperty" => FlowRunner.Spec.Blocks.SetContactProperty,
      "Core.SetGroupMembership" => FlowRunner.Spec.Blocks.SetGroupMembership,
      "MobilePrimitives.SelectOneResponse" => FlowRunner.Spec.Blocks.SelectOneResponse,
      "MobilePrimitives.Message" => FlowRunner.Spec.Blocks.Message,
      "MobilePrimitives.NumericResponse" => FlowRunner.Spec.Blocks.NumericResponse,
      "MobilePrimitives.OpenResponse" => FlowRunner.Spec.Blocks.OpenResponse,
      "Io.Turn.DynamicSelectOneResponse" => FlowRunner.CustomBlocks.DynamicSelectOneResponse,
      "Io.Turn.MetaConversion" => FlowRunner.CustomBlocks.MetaConversion,
      "Io.Turn.ScheduleFlow" => FlowRunner.CustomBlocks.ScheduleFlow,
      "Io.Turn.SendContentMessage" => FlowRunner.CustomBlocks.SendContentMessage,
      "Io.Turn.SetChatProperty" => FlowRunner.CustomBlocks.SetChatProperty,
      "Io.Turn.SetMessageProperty" => FlowRunner.CustomBlocks.SetMessageProperty,
      "Io.Turn.UpdateDictionary" => FlowRunner.CustomBlocks.UpdateDictionary,
      "Io.Turn.WhatsAppCallPermissionRequest" =>
        FlowRunner.CustomBlocks.WhatsAppCallPermissionRequest,
      "Io.Turn.WhatsAppCallToAction" => FlowRunner.CustomBlocks.WhatsAppCallToAction,
      "Io.Turn.WhatsAppCatalog" => FlowRunner.CustomBlocks.WhatsAppCatalog,
      "Io.Turn.WhatsAppRequestLocation" => FlowRunner.CustomBlocks.WhatsAppRequestLocation,
      "Io.Turn.WhatsAppSendFlow" => FlowRunner.CustomBlocks.WhatsAppSendFlow,
      "Io.Turn.WhatsAppTemplateMessage" => FlowRunner.CustomBlocks.WhatsAppTemplateMessage,
      "Io.Turn.Webhook" => FlowRunner.CustomBlocks.Webhook,
      "Io.Turn.Wait" => FlowRunner.CustomBlocks.Wait
    }
  end
end
