defmodule Muzak.Mutators.Constants.Numbers do
  @moduledoc false

  # Mutator changing all hard coded numbers.

  use Muzak.Mutators.Mutator

  def mutate(ast, name_fun) do
    tagged = tag_nodes(ast)

    tagged
    |> strip_typespecs()
    |> Macro.postwalk([], fn node, acc ->
      case mutate(node, tagged, name_fun) do
        :no_mutation -> {node, acc}
        mutation -> {node, [mutation | acc]}
      end
    end)
    |> elem(1)
    |> Enum.uniq()
  end

  def mutate({:__block__, meta, [arg]} = node, ast, rand_func) when is_number(arg) do
    number = arg + rand_func.(:number)

    token =
      if is_integer(number) do
        number
        |> to_string()
        |> String.graphemes()
        |> Enum.reverse()
        |> Enum.chunk_every(3, 3, [])
        |> Enum.map(&Enum.reverse/1)
        |> Enum.intersperse("_")
        |> Enum.reverse()
        |> to_string()
      else
        to_string(number)
      end

    replacement = {:__block__, Keyword.put(meta, :token, token), [number]}

    %{
      mutated_ast: strip_unique_tags(replace_node(ast, node, replacement)),
      line: meta[:line],
      example_format: :line
    }
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

  defp tag_nodes(ast) do
    ast
    |> Macro.postwalk(0, fn
      {op, meta, args} = node, tag when is_ast_op(node) ->
        {{op, Keyword.put(meta, :unique_tag, tag), args}, tag + 1}

      node, tag ->
        {node, tag}
    end)
    |> elem(0)
  end

  def strip_unique_tags(ast) do
    Macro.postwalk(ast, fn
      {op, meta, args} = node when is_ast_op(node) ->
        {op, Keyword.delete(meta, :unique_tag), args}

      node ->
        node
    end)
  end
end
