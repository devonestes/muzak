defmodule Muzak.Mutators.Mutator do
  @moduledoc false
  # Defines the behaviour for a mutator

  @callback mutate(Macro.t(), Macro.t()) ::
              :no_mutation
              | %{
                  mutated_ast: Macro.t(),
                  line: pos_integer(),
                  example_format: :line | {:block, pos_integer()}
                }

  defmacro __using__(_opts) do
    quote do
      @behaviour Muzak.Mutators.Mutator

      defguard is_ast_op(tuple)
               when tuple_size(tuple) == 3 and
                      is_atom(elem(tuple, 0)) and
                      is_list(elem(tuple, 1)) and
                      is_list(elem(tuple, 2))

      import Muzak.Mutators.Mutator, only: [replace_node: 3, random_string: 1]

      @doc false
      def mutate(ast) do
        mutate(ast, &random_string/1)
      end

      @impl true
      @doc false
      def mutate(node, ast) when not is_function(ast) do
        mutate(node, ast, &random_string/1)
      end
    end
  end

  defguard is_ast_op(tuple)
           when tuple_size(tuple) == 3 and
                  is_atom(elem(tuple, 0)) and
                  is_list(elem(tuple, 1)) and
                  is_list(elem(tuple, 2))

  @doc false
  def to_ast_and_state(string) do
    Muzak.Code.Formatter.to_forms_and_state(string)
  end

  @doc false
  def replace_node(ast, node, replacement) do
    Macro.postwalk(ast, fn
      ^node -> replacement
      other_node -> other_node
    end)
  end

  @random_string ?a..?z |> Stream.cycle() |> Enum.take(520) |> Enum.take_random(10) |> to_string()
  @random_number 0..9
                 |> Stream.cycle()
                 |> Enum.take(520)
                 |> Enum.take_random(2)
                 |> Enum.join()
                 |> String.to_integer()

  @doc false
  def random_string(), do: random_string(:string)

  @doc false
  def random_string(:string), do: @random_string
  def random_string(:number), do: @random_number

  def line_from_ast(original_file, line) when is_binary(original_file) do
    original_file
    |> String.split("\n")
    |> Enum.at(line - 1)
  end

  def line_from_ast(ast, original_file, line) do
    line = map_original_line(original_file, line)

    ast
    |> Macro.to_string()
    |> Code.format_string!()
    |> to_string()
    |> String.split("\n")
    |> Enum.at(line - 1)
  end

  defp map_original_line(original_file, original_line) do
    {_, node_to_match} =
      original_file
      |> Code.string_to_quoted!()
      |> Macro.postwalk(nil, fn
        {_, meta, _} = node, acc ->
          if meta[:line] == original_line do
            {node, escape_node(node)}
          else
            {node, acc}
          end

        node, acc ->
          {node, acc}
      end)

    {_, line} =
      original_file
      |> Code.string_to_quoted!()
      |> Macro.to_string()
      |> Code.string_to_quoted!()
      |> Macro.postwalk(nil, fn
        {_, meta, _} = node, nil ->
          if node_to_match == escape_node(node) do
            {node, meta[:line]}
          else
            {node, nil}
          end

        node, acc ->
          {node, acc}
      end)

    line
  end

  defp escape_node({op, _, args}) do
    {escape_node(op), [], escape_node(args)}
  end

  defp escape_node(node) when is_list(node) do
    Enum.map(node, &escape_node/1)
  end

  defp escape_node(node) when is_tuple(node) do
    node
    |> Tuple.to_list()
    |> Enum.map(&escape_node/1)
    |> List.to_tuple()
  end

  defp escape_node(node) do
    node
  end
end
