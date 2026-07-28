defmodule FlowRunner.ExpressionModeTest do
  @moduledoc """
  Proves the expression-language mode threads from `context.private` into
  evaluation. Under `:v2` (stamped, missing stamp, or bare vars map) string
  values are coerced as in expression v2; under `:v3` they pass through
  untouched.
  """
  use ExUnit.Case, async: true

  alias FlowRunner.Context

  defp context(vars, mode \\ nil) do
    context = %Context{vars: vars}
    if mode, do: Context.put_private(context, :expression_mode, mode), else: context
  end

  describe "expression_opts/1" do
    test "resolves the stamped mode" do
      assert FlowRunner.expression_opts(context(%{}, :v3)) == []
      assert FlowRunner.expression_opts(context(%{}, :v2)) == [mode: :v2]
    end

    test "defaults to :v2 for unstamped contexts and bare maps" do
      assert FlowRunner.expression_opts(context(%{})) == [mode: :v2]
      assert FlowRunner.expression_opts(%{"some" => "vars"}) == [mode: :v2]
    end
  end

  describe "evaluate_expression/2" do
    test "a :v2-stamped context coerces string vars" do
      assert FlowRunner.evaluate_expression("@age", context(%{"age" => "30"}, :v2)) == 30
    end

    test "an unstamped context degrades safely to :v2" do
      assert FlowRunner.evaluate_expression("@age", context(%{"age" => "30"})) == 30
    end

    test "a :v3-stamped context preserves string vars" do
      assert FlowRunner.evaluate_expression("@age", context(%{"age" => "30"}, :v3)) == "30"
    end
  end

  describe "evaluate_expression_block/2" do
    test "threads the mode from the context" do
      assert FlowRunner.evaluate_expression_block("age > 21", context(%{"age" => "30"}, :v2)) ==
               true

      assert FlowRunner.evaluate_expression_block("age", context(%{"age" => "30"}, :v3)) ==
               "30"
    end
  end

  describe "evaluate_expression_as_string!/2" do
    test "renders under the stamped mode" do
      vars = %{"date" => "2020-12-13T23:34:45"}

      assert FlowRunner.evaluate_expression_as_string!("@date", context(vars, :v2)) ==
               "2020-12-13T23:34:45.0Z"

      assert FlowRunner.evaluate_expression_as_string!("@date", context(vars, :v3)) ==
               "2020-12-13T23:34:45"
    end
  end
end
