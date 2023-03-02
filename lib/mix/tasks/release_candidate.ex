defmodule Mix.Tasks.FlowRunner.ReleaseCandidate do
  use Mix.Task
  use VersionTasks.FnExpr
  alias Mix.Tasks.Version.Current

  @shortdoc "The next version (e.g v0.9.2)"
  def run(_args) do
    current = Current.calc(["patch"])
    next = calc(["rc"])
    IO.puts("Updating mix.exs from #{current} to #{next}")

    update_file("mix.exs", current, next, &update_mix_version/3)
    update_file("README.md", current, next, &update_readme_version/3)
  end

  defp update_file(filename, current, next, update_fn) do
    if File.exists?(filename) do
      IO.puts("  -- Updating #{filename}")

      filename
      |> File.read()
      |> invoke(fn {:ok, content} -> content end)
      |> String.split("\n")
      |> Enum.map(fn line -> update_fn.(line, current, next) end)
      |> Enum.join("\n")
      |> invoke(fn content -> File.write!(filename, content) end)
    else
      IO.puts("  -- Skipping missing file #{filename}")
    end
  end

  defp update_mix_version(line, current, next) do
    line
    |> String.replace("@version \"#{current}\"", "@version \"#{next}\"")
    |> String.replace("version: \"#{current}\"", "version: \"#{next}\"")
  end

  defp update_readme_version(line, current, next) do
    line
    |> String.replace("~> #{current}", "~> #{next}")
  end

  def calc([]), do: calc(["patch"])

  def calc([mode]) do
    Current.calc()
    |> String.split(".")
    |> uptick(mode)
  end

  def uptick([major, minor, patch], "rc") do
    {major, ""} = Integer.parse(major)

    {major, patch, rc_patch} =
      case Integer.parse(patch) do
        {patch_val, ""} ->
          {major + 1, patch_val, "rc0"}

        {patch_val, "-rc" <> existing_rc} ->
          {rc_val, ""} = Integer.parse(existing_rc)
          {major, patch_val, "rc#{rc_val + 1}"}
      end

    "#{major}.#{minor}.#{patch}-#{rc_patch}"
  end
end
