defmodule Muzak.Mutators.Constants.StringsTest do
  use Assertions.Case, async: true

  alias Muzak.{Code.Formatter, Mutators.Mutator, Mutators.Constants.Strings}

  describe "mutate/2" do
    test "returns all expected mutations" do
      ast = Formatter.to_ast(~s|
        defmodule Tester do
          @doc "a string doc that shouldn't mutate"
          def heredoc() do
            """
            Heredoc
            """ <> "other string"
          end
        end
        |)

      ast
      |> Strings.mutate(fn _ -> "random_string" end)
      |> assert_lists_equal([
        %{
          example_format: :line,
          line: 7,
          mutated_ast: {
            :defmodule,
            [do: [line: 2], end: [line: 9], line: 2],
            [
              {:__aliases__, [{:last, [line: 2]}, {:line, 2}], [:Tester]},
              [
                {
                  {:__block__, [line: 2], [:do]},
                  {
                    :__block__,
                    [],
                    [
                      {
                        :@,
                        [end_of_expression: [newlines: 1, line: 3], line: 3],
                        [
                          {:doc, [line: 3],
                           [
                             {:__block__, [delimiter: "\"", line: 3],
                              ["a string doc that shouldn't mutate"]}
                           ]}
                        ]
                      },
                      {
                        :def,
                        [do: [line: 4], end: [line: 8], line: 4],
                        [
                          {:heredoc, [closing: [line: 4], line: 4], []},
                          [
                            {
                              {:__block__, [line: 4], [:do]},
                              {
                                :<>,
                                [line: 7],
                                [
                                  {:__block__,
                                   [{:delimiter, "\"\"\""}, {:indentation, 12}, {:line, 5}],
                                   ["Heredoc\n"]},
                                  {:__block__, [delimiter: "\"", line: 7], ["random_string"]}
                                ]
                              }
                            }
                          ]
                        ]
                      }
                    ]
                  }
                }
              ]
            ]
          }
        },
        %{
          example_format: :line,
          line: 5,
          mutated_ast: {
            :defmodule,
            [do: [line: 2], end: [line: 9], line: 2],
            [
              {:__aliases__, [{:last, [line: 2]}, {:line, 2}], [:Tester]},
              [
                {
                  {:__block__, [line: 2], [:do]},
                  {
                    :__block__,
                    [],
                    [
                      {
                        :@,
                        [end_of_expression: [newlines: 1, line: 3], line: 3],
                        [
                          {:doc, [line: 3],
                           [
                             {:__block__, [delimiter: "\"", line: 3],
                              ["a string doc that shouldn't mutate"]}
                           ]}
                        ]
                      },
                      {
                        :def,
                        [do: [line: 4], end: [line: 8], line: 4],
                        [
                          {:heredoc, [closing: [line: 4], line: 4], []},
                          [
                            {
                              {:__block__, [line: 4], [:do]},
                              {
                                :<>,
                                [line: 7],
                                [
                                  {:__block__,
                                   [{:delimiter, "\"\"\""}, {:indentation, 12}, {:line, 5}],
                                   ["random_string"]},
                                  {:__block__, [delimiter: "\"", line: 7], ["other string"]}
                                ]
                              }
                            }
                          ]
                        ]
                      }
                    ]
                  }
                }
              ]
            ]
          }
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
            "putting it #\{arg}" <> "other string"
          end
        end
        """)

      node =
        {:<<>>, [delimiter: "\"", line: 3],
         [
           "putting it ",
           {:"::", [line: 3],
            [
              {{:., [line: 3], [Kernel, :to_string]}, [closing: [line: 3], line: 3],
               [{:arg, [line: 3], nil}]},
              {:binary, [line: 3], nil}
            ]}
         ]}

      mutation =
        {:<<>>, [delimiter: "\"", line: 3],
         [
           "random_string",
           {:"::", [line: 3],
            [
              {{:., [line: 3], [Kernel, :to_string]}, [closing: [line: 3], line: 3],
               [{:arg, [line: 3], nil}]},
              {:binary, [line: 3], nil}
            ]}
         ]}

      assert Strings.mutate(node, ast, fn _ -> "random_string" end) == [
               %{
                 mutated_ast: Mutator.replace_node(ast, node, mutation),
                 line: 3,
                 example_format: :line
               }
             ]
    end

    test "returns the correct result (mutation expected part 2)" do
      ast =
        Formatter.to_ast("""
        defmodule Tester do
          def test_fun(arg) do
            "putting it #\{arg}" <> "other string"
          end
        end
        """)

      node = {:__block__, [delimiter: "\"", line: 3], ["other string"]}

      mutation = {:__block__, [delimiter: "\"", line: 3], ["random_string"]}

      assert Strings.mutate(node, ast, fn _ -> "random_string" end) == [
               %{
                 mutated_ast: Mutator.replace_node(ast, node, mutation),
                 line: 3,
                 example_format: :line
               }
             ]
    end
  end
end
