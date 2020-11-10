defmodule Muzak.Mutators.Constants.Numbers do
  @moduledoc false
  # Mutator changing all hard coded numbers.

  use Muzak.Mutators.Mutator

  def mutate(ast, name_fun) do
    ast
    |> strip_typespecs()
    |> Macro.postwalk([], fn node, acc ->
      case mutate(node, ast, name_fun) do
        :no_mutation -> {node, acc}
        mutation -> {node, [mutation | acc]}
      end
    end)
    |> elem(1)
    |> Enum.uniq()
  end

  def mutate({:__block__, meta, [arg]} = node, ast, rand_func) when is_number(arg) do
    number = rand_func.(:number)

    token =
      number
      |> to_string()
      |> String.graphemes()
      |> Enum.reverse()
      |> Enum.chunk_every(3, 3, [])
      |> Enum.map(&Enum.reverse/1)
      |> Enum.intersperse("_")
      |> Enum.reverse()
      |> to_string()

    replacement = {:__block__, Keyword.put(meta, :token, token), [number]}
    %{mutated_ast: replace_node(ast, node, replacement), line: meta[:line], example_format: :line}
  end

  def mutate(_, _, _) do
    :no_mutation
  end

  @to_strip [:type, :spec, :callback, :impl]
  defp strip_typespecs(ast) do
    Macro.postwalk(ast, fn node ->
      if match?({:@, _, [{op, _, _} | _]} when op in @to_strip, node) do
        {:@, [], []}
      else
        node
      end
    end)
  end
end
