defmodule Mix.Tasks.FlowRunner.ReleaseCandidate do
  @shortdoc "The next release candidate version (e.g v2.0.0-rc0)"
  @moduledoc """
  #{@shortdoc}
    
  Ugly module to add the minimum necessary to allow version.tasks to do
  release candidates. The standard release only does major, minor, patch
  """
  use Mix.Task

  def run(_args) do
    current = Mix.Tasks.Version.Current.calc(["patch"])
    next = calc(["rc"])
    IO.puts("Updating mix.exs from #{current} to #{next}")

    update_file("mix.exs", current, next, &update_mix_version/3)
    update_file("README.md", current, next, &update_readme_version/3)

    IO.puts("Committing updates to git")
    repo = Git.new(".")
    {:ok, _} = Git.add(repo, ["mix.exs", "README.md"])
    {:ok, output} = Git.commit(repo, ["-m", "v#{next}"])
    IO.puts(output)
  end

  defp update_file(filename, current, next, update_fn) do
    if File.exists?(filename) do
      IO.puts("  -- Updating #{filename}")

      filename
      |> File.read()
      |> then(fn {:ok, content} -> content end)
      |> String.split("\n")
      |> Enum.map_join("\n", fn line -> update_fn.(line, current, next) end)
      |> then(fn content -> File.write!(filename, content) end)
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
    Mix.Tasks.Version.Current.calc()
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
