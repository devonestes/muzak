defmodule Muzak.Mutators.Constants.NumbersTest do
  use Assertions.Case, async: true

  alias Muzak.{Code.Formatter, Mutators.Mutator, Mutators.Constants.Numbers}

  describe "mutate/2" do
    test "returns all expected mutations" do
      ast =
        Formatter.to_ast("""
        defmodule Tester do
          @type thing() :: 3 | 4

          @spec test_fun(1 | 2) :: number()
          def test_fun(arg) do
            1 + arg - 3.02 / -2 + 0
            [name: 0, other: 1]
            [9, 8]
          end
        end
        """)

      node1 = {:__block__, [token: "1", line: 6], [1]}
      mutation1 = {:__block__, [token: "2", line: 6], [2]}

      node2 = {:__block__, [token: "3.02", line: 6], [3.02]}
      mutation2 = {:__block__, [token: "4.02", line: 6], [4.02]}

      node3 = {:__block__, [token: "2", line: 6], [2]}
      mutation3 = {:__block__, [token: "3", line: 6], [3]}

      node4 = {:__block__, [token: "0", line: 6], [0]}
      mutation4 = {:__block__, [token: "1", line: 6], [1]}

      node5 = {:__block__, [token: "1", line: 7], [1]}
      mutation5 = {:__block__, [token: "2", line: 7], [2]}

      node6 = {:__block__, [token: "0", line: 7], [0]}
      mutation6 = {:__block__, [token: "1", line: 7], [1]}

      node7 = {:__block__, [token: "9", line: 8], [9]}
      mutation7 = {:__block__, [token: "10", line: 8], [10]}

      node8 = {:__block__, [token: "8", line: 8], [8]}
      mutation8 = {:__block__, [token: "9", line: 8], [9]}

      ast
      |> Numbers.mutate(fn _ -> 1 end)
      |> assert_lists_equal([
        %{
          mutated_ast: Mutator.replace_node(ast, node1, mutation1),
          line: 6,
          example_format: :line
        },
        %{
          mutated_ast: Mutator.replace_node(ast, node2, mutation2),
          line: 6,
          example_format: :line
        },
        %{
          mutated_ast: Mutator.replace_node(ast, node3, mutation3),
          line: 6,
          example_format: :line
        },
        %{
          mutated_ast: Mutator.replace_node(ast, node4, mutation4),
          line: 6,
          example_format: :line
        },
        %{
          mutated_ast: Mutator.replace_node(ast, node5, mutation5),
          line: 7,
          example_format: :line
        },
        %{
          mutated_ast: Mutator.replace_node(ast, node6, mutation6),
          line: 7,
          example_format: :line
        },
        %{
          mutated_ast: Mutator.replace_node(ast, node7, mutation7),
          line: 8,
          example_format: :line
        },
        %{
          mutated_ast: Mutator.replace_node(ast, node8, mutation8),
          line: 8,
          example_format: :line
        }
      ])
    end
  end

  describe "mutate/3" do
    test "returns the correct result (mutation expected part 1)" do
      ast =
        Formatter.to_ast("""
        defmodule Tester do
          def test_fun(arg) do
            1 + arg - 3.02 / -2 + 0
            [name: 0..1]
          end
        end
        """)

      node = {:__block__, [token: "1", line: 3], [1]}

      mutation = {:__block__, [token: "792_763", line: 3], [792_763]}

      assert Numbers.mutate(node, ast, fn _ -> 792_762 end) == %{
               mutated_ast: Mutator.replace_node(ast, node, mutation),
               line: 3,
               example_format: :line
             }
    end
  end
end
