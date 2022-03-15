defmodule FlowRunner.ContextTest do
  use ExUnit.Case
  alias FlowRunner.Context

  test "put_private/3" do
    assert %Context{private: %{foo: "bar"}} == Context.put_private(%Context{}, :foo, "bar")
  end

  test "clone_empty/1" do
    assert %Context{language: "eng", mode: "TEXT"} ==
             Context.clone_empty(%Context{
               language: "eng",
               mode: "TEXT",
               vars: %{foo: "bar"},
               private: %{foo: "bar"}
             })
  end
end
