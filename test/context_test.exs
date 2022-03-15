defmodule FlowRunner.ContextTest do
  use ExUnit.Case
  alias FlowRunner.Context

  test "put_private/3" do
    assert %Context{private: %{foo: "bar"}} == Context.put_private(%Context{}, :foo, "bar")
  end
end
