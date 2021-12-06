defmodule FlowRunner.Builder.Floip1 do
  @moduledoc """
  A module to make it easier to create flows without needing
  to write the JSON manually
  """
  use FlowRunner.FlowBuilder

  language(:eng, "English")
  name("My flow")
  description("The description")

  flow :first_flow, timeout: minutes(1) do
    block :prompt do
      prompt("Hello world",
        reply_1: "Send me reply 1",
        reply_2: "Send me reply 2"
      )
    end

    block :reply_1 do
      text("This is reply 1")
    end

    block :reply_2 do
      text("This is reply 2")
    end
  end

  flow :second_flow do
    block(:second_prompt, do: text("This is the second flow"))
  end

  translation :afr, "Afrikaans" do
    %{
      "Hello world" => "Hello Wêreld",
      "Send me reply 1" => "Stuur vir my antwoord 1",
      "Send me reply 2" => "Stuur vir my antwoord 2",
      "This is reply 1" => "Dit is antwoord 1",
      "This is reply 2" => "Dit is antwoord 2",
      "This is the second flow" => "Dit is die tweede vloei"
    }
  end
end
