defmodule Muzak.Mutators.Constants.Strings do
  @moduledoc false

  # Mutator changing all hard coded strings.

  use Muzak.Mutators.Mutator

  def mutate(ast, name_fun) do
    ast
    |> strip_typespecs()
    |> Macro.postwalk([], fn node, acc ->
      case mutate(node, ast, name_fun) do
        :no_mutation -> {node, acc}
        mutations -> {node, mutations ++ acc}
      end
    end)
    |> elem(1)
    |> Enum.uniq()
  end

  def mutate({:__block__, meta, [arg]} = node, ast, rand_func) when is_binary(arg) do
    string = rand_func.(:string)

    replacement = {:__block__, meta, [string]}

    [
      %{
        mutated_ast: replace_node(ast, node, replacement),
        line: meta[:line],
        example_format: :line
      }
    ]
  end

  def mutate({:<<>>, meta, args} = node, ast, rand_func) when is_list(args) do
    args
    |> Enum.with_index()
    |> Enum.reduce([], fn
      {arg, idx}, acc when is_binary(arg) ->
        replacment_args = List.replace_at(args, idx, rand_func.(:string))
        replacement = {:<<>>, meta, replacment_args}

        [
          %{
            mutated_ast: replace_node(ast, node, replacement),
            line: meta[:line],
            example_format: :line
          }
          | acc
        ]

      _, acc ->
        acc
    end)
  end

  def mutate(_, _, _) do
    :no_mutation
  end

  @to_strip [:doc, :moduledoc, :typedoc]
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
