defmodule FlowRunner.BlockAutodoc do
  @moduledoc """
  Compile-time documentation collection for FLOIP block modules.

  This macro module enables automatic documentation generation for FLOIP blocks,
  mirroring the pattern used by `Expression.Autodoc` for expression functions.

  ## Usage

  Add `use FlowRunner.BlockAutodoc` to any block module and annotate block types
  with `@block_category` and `@block_doc` attributes:

      defmodule FlowRunner.CustomBlocks.MyBlock do
        use FlowRunner.BlockAutodoc

        @block_category "control"
        @block_doc type: "Io.Turn.MyBlock",
                   dsl_name: "my_block()",
                   description: "Does something useful.",
                   config: %{
                     "param" => %{type: "string", required: true, description: "A parameter"}
                   },
                   example: \"""
                   card MyCard do
                     my_block("value")
                   end
                   \"""

        # ... block implementation
      end

  ## @block_doc Attribute Schema

  | Field | Required | Description |
  |-------|----------|-------------|
  | `type` | Yes | Block type string (e.g., `"Io.Turn.Wait"`) |
  | `dsl_name` | Yes | Human-readable name for docs (e.g., `"wait()"`) |
  | `description` | Yes | Human-readable description |
  | `config` | Yes | Map of config fields with type, required, description |
  | `example` | No | DSL code example |
  | `returns` | No | What the block sets in context |
  | `notes` | No | Additional usage notes |
  | `deprecated` | No | Boolean, marks deprecated blocks |
  | `deprecated_in_favor_of` | No | Replacement block type |
  | `deprecated_in_favor_of_dsl_name` | No | Replacement block dsl_name for display |

  At compile time, this macro generates a `block_docs/0` function that returns
  all documented blocks with their category attached.
  """

  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :block_doc, accumulate: true)
      Module.register_attribute(__MODULE__, :block_category, [])
      @before_compile FlowRunner.BlockAutodoc
    end
  end

  defmacro __before_compile__(env) do
    block_docs = Module.get_attribute(env.module, :block_doc) || []
    category = Module.get_attribute(env.module, :block_category)

    quote do
      @doc """
      Returns all block documentation defined in this module.

      Each block doc entry is a keyword list with keys like `:type`, `:description`,
      `:config`, etc., plus a `:category` key added from `@block_category`.
      """
      @spec block_docs() :: [Keyword.t()]
      def block_docs do
        unquote(Macro.escape(block_docs))
        |> Enum.map(fn doc -> Keyword.put(doc, :category, unquote(category)) end)
      end
    end
  end
end
