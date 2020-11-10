defmodule Muzak.Mutators.Functions.Rename do
  @moduledoc false
  # Mutator for changing the names of modules

  use Muzak.Mutators.Mutator

  def mutate(ast, name_fun) do
    Macro.postwalk(ast, [], fn node, acc ->
      case mutate(node, ast, name_fun) do
        :no_mutation -> {node, acc}
        mutation -> {node, [mutation | acc]}
      end
    end)
    |> elem(1)
  end

  @ops [:def, :defp, :defmacro, :defmacrop]

  @doc false
  def mutate({op, meta, [{_, fun_meta, args}, impl]} = node, ast, name_fun) when op in @ops do
    name = String.to_atom(name_fun.(:string))
    mutation = {op, meta, [{name, fun_meta, args}, impl]}
    replacement = replace_node(ast, node, mutation)
    %{mutated_ast: replacement, line: meta[:line], example_format: :line}
  end

  def mutate(_, _, _) do
    :no_mutation
  end
end
