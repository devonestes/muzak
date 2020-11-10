defmodule Muzak.Mutations do
  @moduledoc false

  alias Muzak.Code.Formatter

  @mutators [
    Muzak.Mutators.Constants.Numbers,
    Muzak.Mutators.Functions.Rename
  ]

  @doc false
  def generate_mutations(opts) do
    Mix.Project.config()
    |> Keyword.get(:elixirc_paths)
    |> Enum.flat_map(&ls_r/1)
    |> Enum.filter(fn path -> opts[:only] in [nil, path] end)
    |> Enum.shuffle()
    |> Enum.reduce([], &read_file/2)
    |> Enum.map(fn info -> Task.async(fn -> mutate_file(info) end) end)
    |> Enum.reduce([], &reduce_mutations(&1, &2, 25))
    |> Enum.take(25)
end

  @doc false
  def mutate_file(info, name_fun \\ &Muzak.Mutators.Mutator.random_string/1) do
    mutate_file(info, @mutators, name_fun)
  end

  @doc false
  def mutate_file({file, path}, mutators, name_fun) do
    {ast, state} = Formatter.to_forms_and_state(file)

    mutators
    |> Enum.flat_map(&mutate(&1, file, path, ast, state, name_fun))
    |> Enum.shuffle()
  end

  defp reduce_mutations(ref, acc, num_mutations) when length(acc) >= num_mutations do
    Task.shutdown(ref, :brutal_kill)
    acc
  end

  defp reduce_mutations(ref, acc, _) do
    ref |> Task.await(:infinity) |> Kernel.++(acc) |> Enum.uniq()
  end

  defp read_file(path, acc) do
    file = path |> Path.expand() |> File.read!() |> Code.format_string!() |> to_string()
    [{file, path} | acc]
  rescue
    _ ->
      acc
  end

  defp mutate(mutator, file, path, ast, state, name_fun) do
    ast
    |> mutator.mutate(name_fun)
    |> Enum.reduce([], &[&1 | &2])
    |> Enum.uniq()
    |> Enum.map(&expand_mutation(&1, file, path, state))
  end

  defp expand_mutation(mutation, original_file, path, state) do
    original_algebra = Formatter.to_algebra(original_file)
    mutated_file = Formatter.to_algebra(mutation.mutated_ast, state)

    {mutated, original} = get_lines(mutated_file, original_algebra, mutation.example_format)

    %{
      line: mutation.line,
      path: path,
      original_file: original_file,
      file: to_string(mutated_file),
      mutation: mutated,
      original: original
    }
  end

  defp get_lines(file, original_file, :line) do
    chunk_fun = fn element, acc ->
      if String.starts_with?(element, "\n") do
        element = String.replace_leading(element, "\n\n", "\n")
        [newline | spaces] = String.graphemes(element)
        {:cont, Enum.reverse(acc), [newline, Enum.join(spaces)]}
      else
        if match?(["\n", _], acc) do
          {:cont, [element | tl(acc)]}
        else
          {:cont, [element | acc]}
        end
      end
    end

    after_fun = fn
      [] -> {:cont, []}
      acc -> {:cont, Enum.reverse(acc), []}
    end

    file = Enum.chunk_while(file, [], chunk_fun, after_fun)
    original_file = Enum.chunk_while(original_file, [], chunk_fun, after_fun)

    {original, mutated} =
      original_file
      |> Enum.zip(file)
      |> Enum.filter(fn {original, mutated} -> original != mutated end)
      |> Enum.reduce({[], []}, fn {original, mutated}, {original_acc, mutated_acc} ->
        {[original | original_acc], [mutated | mutated_acc]}
      end)

    {_, original} =
      original
      |> Enum.reverse()
      |> Enum.reduce({nil, []}, &trim/2)

    {_, mutated} =
      mutated
      |> Enum.reverse()
      |> Enum.reduce({nil, []}, &trim/2)

    {List.flatten(mutated), List.flatten(original)}
  end

  defp get_lines(file, original_file, {:block, original_lines, mutated_lines}) do
    chunk_fun = fn element, acc ->
      if String.starts_with?(element, "\n") do
        element = String.replace_leading(element, "\n\n", "\n")
        [newline | spaces] = String.graphemes(element)
        {:cont, Enum.reverse(acc), [newline, Enum.join(spaces)]}
      else
        if match?(["\n", _], acc) do
          {:cont, [element | tl(acc)]}
        else
          {:cont, [element | acc]}
        end
      end
    end

    after_fun = fn
      [] -> {:cont, []}
      acc -> {:cont, Enum.reverse(acc), []}
    end

    file = Enum.chunk_while(file, [], chunk_fun, after_fun)

    original_file = Enum.chunk_while(original_file, [], chunk_fun, after_fun)

    start_idx =
      file
      |> Enum.zip(original_file)
      |> Enum.find_index(fn {mutated, original} -> mutated != original end)
      |> Kernel.-(1)

    original =
      Enum.slice(original_file, start_idx..(start_idx + original_lines - 1))
      |> Enum.intersperse(["\n"])

    mutated =
      Enum.slice(file, start_idx..(start_idx + mutated_lines - 1))
      |> Enum.intersperse(["\n"])

    {_, original} = Enum.reduce(original, {nil, []}, &trim/2)
    {_, mutated} = Enum.reduce(mutated, {nil, []}, &trim/2)

    {List.flatten(Enum.reverse(mutated)), List.flatten(Enum.reverse(original))}
  end

  defp trim([maybe_space | rest] = line, {nil, lines}) do
    if String.starts_with?(maybe_space, " ") do
      {String.codepoints(maybe_space), [rest | lines]}
    else
      {String.codepoints("😀"), [line | lines]}
    end
  end

  defp trim([maybe_space | rest], {pad, lines}) do
    first =
      maybe_space
      |> String.codepoints()
      |> Kernel.--(pad)
      |> Enum.join()

    {pad, [[first | rest] | lines]}
  end

  defp ls_r(path) do
    if File.dir?(path) do
      path
      |> File.ls!()
      |> Enum.map(&Path.join(path, &1))
      |> Enum.flat_map(&ls_r/1)
    else
      [path]
    end
  end
end
