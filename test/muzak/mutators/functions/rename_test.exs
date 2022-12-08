defmodule Muzak.Mutators.Functions.RenameTest do
  use ExUnit.Case, async: true

  alias Muzak.{Code.Formatter, Mutators.Functions.Rename}

  @ast Formatter.to_ast("""
       defmodule Tester do
         defmacrop priv_macro(arg) do
           quote do
             priv_fun(arg)
           end
         end

         defmacro my_macro(arg) do
           quote do
             my_fun(arg)
           end
         end

         def my_fun(arg), do: priv_fun(arg)

         defp priv_fun(arg) do
           arg + 1
         end
       end
       """)

  describe "mutate/2" do
    test "changes the name of functions and macros (part 1)" do
      node =
        {:defmacrop,
         [
           end_of_expression: [newlines: 2, line: 6],
           do: [line: 2],
           end: [line: 6],
           line: 2
         ],
         [
           {:priv_macro, [closing: [line: 2], line: 2], [{:arg, [line: 2], nil}]},
           [
             {{:__block__, [line: 2], [:do]},
              {:quote, [do: [line: 3], end: [line: 5], line: 3],
               [
                 [
                   {{:__block__, [line: 3], [:do]},
                    {:priv_fun, [closing: [line: 4], line: 4], [{:arg, [line: 4], nil}]}}
                 ]
               ]}}
           ]
         ]}

      assert Rename.mutate(node, @ast, &name_fun/1) == %{
               example_format: :line,
               line: 2,
               mutated_ast: {
                 :defmodule,
                 [do: [line: 1], end: [line: 19], line: 1],
                 [
                   {:__aliases__, [{:last, [line: 1]}, {:line, 1}], [:Tester]},
                   [
                     {
                       {:__block__, [line: 1], [:do]},
                       {
                         :__block__,
                         [],
                         [
                           {
                             :defmacrop,
                             [
                               end_of_expression: [newlines: 2, line: 6],
                               do: [line: 2],
                               end: [line: 6],
                               line: 2
                             ],
                             [
                               {:random_function, [closing: [line: 2], line: 2],
                                [{:arg, [line: 2], nil}]},
                               [
                                 {
                                   {:__block__, [line: 2], [:do]},
                                   {
                                     :quote,
                                     [do: [line: 3], end: [line: 5], line: 3],
                                     [
                                       [
                                         {
                                           {:__block__, [line: 3], [:do]},
                                           {:priv_fun, [closing: [line: 4], line: 4],
                                            [{:arg, [line: 4], nil}]}
                                         }
                                       ]
                                     ]
                                   }
                                 }
                               ]
                             ]
                           },
                           {
                             :defmacro,
                             [
                               end_of_expression: [newlines: 2, line: 12],
                               do: [line: 8],
                               end: [line: 12],
                               line: 8
                             ],
                             [
                               {:my_macro, [closing: [line: 8], line: 8],
                                [{:arg, [line: 8], nil}]},
                               [
                                 {
                                   {:__block__, [line: 8], [:do]},
                                   {
                                     :quote,
                                     [do: [line: 9], end: [line: 11], line: 9],
                                     [
                                       [
                                         {
                                           {:__block__, [line: 9], [:do]},
                                           {:my_fun, [closing: [line: 10], line: 10],
                                            [{:arg, [line: 10], nil}]}
                                         }
                                       ]
                                     ]
                                   }
                                 }
                               ]
                             ]
                           },
                           {
                             :def,
                             [end_of_expression: [newlines: 2, line: 14], line: 14],
                             [
                               {:my_fun, [closing: [line: 14], line: 14],
                                [{:arg, [line: 14], nil}]},
                               [
                                 {
                                   {:__block__, [{:format, :keyword}, {:line, 14}], [:do]},
                                   {:priv_fun, [closing: [line: 14], line: 14],
                                    [{:arg, [line: 14], nil}]}
                                 }
                               ]
                             ]
                           },
                           {
                             :defp,
                             [do: [line: 16], end: [line: 18], line: 16],
                             [
                               {:priv_fun, [closing: [line: 16], line: 16],
                                [{:arg, [line: 16], nil}]},
                               [
                                 {
                                   {:__block__, [line: 16], [:do]},
                                   {:+, [line: 17],
                                    [
                                      {:arg, [line: 17], nil},
                                      {:__block__, [token: "1", line: 17], [1]}
                                    ]}
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
    end

    test "changes the name of functions and macros (part 2)" do
      node =
        {:defmacro,
         [
           end_of_expression: [newlines: 2, line: 12],
           do: [line: 8],
           end: [line: 12],
           line: 8
         ],
         [
           {:my_macro, [closing: [line: 8], line: 8], [{:arg, [line: 8], nil}]},
           [
             {{:__block__, [line: 8], [:do]},
              {:quote, [do: [line: 9], end: [line: 11], line: 9],
               [
                 [
                   {{:__block__, [line: 9], [:do]},
                    {:my_fun, [closing: [line: 10], line: 10], [{:arg, [line: 10], nil}]}}
                 ]
               ]}}
           ]
         ]}

      assert Rename.mutate(node, @ast, &name_fun/1) == %{
               example_format: :line,
               line: 8,
               mutated_ast: {
                 :defmodule,
                 [do: [line: 1], end: [line: 19], line: 1],
                 [
                   {:__aliases__, [{:last, [line: 1]}, {:line, 1}], [:Tester]},
                   [
                     {
                       {:__block__, [line: 1], [:do]},
                       {
                         :__block__,
                         [],
                         [
                           {
                             :defmacrop,
                             [
                               end_of_expression: [newlines: 2, line: 6],
                               do: [line: 2],
                               end: [line: 6],
                               line: 2
                             ],
                             [
                               {:priv_macro, [closing: [line: 2], line: 2],
                                [{:arg, [line: 2], nil}]},
                               [
                                 {
                                   {:__block__, [line: 2], [:do]},
                                   {
                                     :quote,
                                     [do: [line: 3], end: [line: 5], line: 3],
                                     [
                                       [
                                         {
                                           {:__block__, [line: 3], [:do]},
                                           {:priv_fun, [closing: [line: 4], line: 4],
                                            [{:arg, [line: 4], nil}]}
                                         }
                                       ]
                                     ]
                                   }
                                 }
                               ]
                             ]
                           },
                           {
                             :defmacro,
                             [
                               end_of_expression: [newlines: 2, line: 12],
                               do: [line: 8],
                               end: [line: 12],
                               line: 8
                             ],
                             [
                               {:random_function, [closing: [line: 8], line: 8],
                                [{:arg, [line: 8], nil}]},
                               [
                                 {
                                   {:__block__, [line: 8], [:do]},
                                   {
                                     :quote,
                                     [do: [line: 9], end: [line: 11], line: 9],
                                     [
                                       [
                                         {
                                           {:__block__, [line: 9], [:do]},
                                           {:my_fun, [closing: [line: 10], line: 10],
                                            [{:arg, [line: 10], nil}]}
                                         }
                                       ]
                                     ]
                                   }
                                 }
                               ]
                             ]
                           },
                           {
                             :def,
                             [end_of_expression: [newlines: 2, line: 14], line: 14],
                             [
                               {:my_fun, [closing: [line: 14], line: 14],
                                [{:arg, [line: 14], nil}]},
                               [
                                 {
                                   {:__block__, [{:format, :keyword}, {:line, 14}], [:do]},
                                   {:priv_fun, [closing: [line: 14], line: 14],
                                    [{:arg, [line: 14], nil}]}
                                 }
                               ]
                             ]
                           },
                           {
                             :defp,
                             [do: [line: 16], end: [line: 18], line: 16],
                             [
                               {:priv_fun, [closing: [line: 16], line: 16],
                                [{:arg, [line: 16], nil}]},
                               [
                                 {
                                   {:__block__, [line: 16], [:do]},
                                   {:+, [line: 17],
                                    [
                                      {:arg, [line: 17], nil},
                                      {:__block__, [token: "1", line: 17], [1]}
                                    ]}
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
    end

    test "changes the name of functions and macros (part 3)" do
      node =
        {:def, [end_of_expression: [newlines: 2, line: 14], line: 14],
         [
           {:my_fun, [closing: [line: 14], line: 14], [{:arg, [line: 14], nil}]},
           [
             {{:__block__, [format: :keyword, line: 14], [:do]},
              {:priv_fun, [closing: [line: 14], line: 14], [{:arg, [line: 14], nil}]}}
           ]
         ]}

      assert Rename.mutate(node, @ast, &name_fun/1) == %{
               example_format: :line,
               line: 14,
               mutated_ast: {
                 :defmodule,
                 [do: [line: 1], end: [line: 19], line: 1],
                 [
                   {:__aliases__, [{:last, [line: 1]}, {:line, 1}], [:Tester]},
                   [
                     {
                       {:__block__, [line: 1], [:do]},
                       {
                         :__block__,
                         [],
                         [
                           {
                             :defmacrop,
                             [
                               end_of_expression: [newlines: 2, line: 6],
                               do: [line: 2],
                               end: [line: 6],
                               line: 2
                             ],
                             [
                               {:priv_macro, [closing: [line: 2], line: 2],
                                [{:arg, [line: 2], nil}]},
                               [
                                 {
                                   {:__block__, [line: 2], [:do]},
                                   {
                                     :quote,
                                     [do: [line: 3], end: [line: 5], line: 3],
                                     [
                                       [
                                         {
                                           {:__block__, [line: 3], [:do]},
                                           {:priv_fun, [closing: [line: 4], line: 4],
                                            [{:arg, [line: 4], nil}]}
                                         }
                                       ]
                                     ]
                                   }
                                 }
                               ]
                             ]
                           },
                           {
                             :defmacro,
                             [
                               end_of_expression: [newlines: 2, line: 12],
                               do: [line: 8],
                               end: [line: 12],
                               line: 8
                             ],
                             [
                               {:my_macro, [closing: [line: 8], line: 8],
                                [{:arg, [line: 8], nil}]},
                               [
                                 {
                                   {:__block__, [line: 8], [:do]},
                                   {
                                     :quote,
                                     [do: [line: 9], end: [line: 11], line: 9],
                                     [
                                       [
                                         {
                                           {:__block__, [line: 9], [:do]},
                                           {:my_fun, [closing: [line: 10], line: 10],
                                            [{:arg, [line: 10], nil}]}
                                         }
                                       ]
                                     ]
                                   }
                                 }
                               ]
                             ]
                           },
                           {
                             :def,
                             [end_of_expression: [newlines: 2, line: 14], line: 14],
                             [
                               {:random_function, [closing: [line: 14], line: 14],
                                [{:arg, [line: 14], nil}]},
                               [
                                 {
                                   {:__block__, [{:format, :keyword}, {:line, 14}], [:do]},
                                   {:priv_fun, [closing: [line: 14], line: 14],
                                    [{:arg, [line: 14], nil}]}
                                 }
                               ]
                             ]
                           },
                           {
                             :defp,
                             [do: [line: 16], end: [line: 18], line: 16],
                             [
                               {:priv_fun, [closing: [line: 16], line: 16],
                                [{:arg, [line: 16], nil}]},
                               [
                                 {
                                   {:__block__, [line: 16], [:do]},
                                   {:+, [line: 17],
                                    [
                                      {:arg, [line: 17], nil},
                                      {:__block__, [token: "1", line: 17], [1]}
                                    ]}
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
    end

    test "changes the name of functions and macros (part 4)" do
      node =
        {:defp, [do: [line: 16], end: [line: 18], line: 16],
         [
           {:priv_fun, [closing: [line: 16], line: 16], [{:arg, [line: 16], nil}]},
           [
             {{:__block__, [line: 16], [:do]},
              {:+, [line: 17],
               [
                 {:arg, [line: 17], nil},
                 {:__block__, [token: "1", line: 17], [1]}
               ]}}
           ]
         ]}

      assert Rename.mutate(node, @ast, &name_fun/1) == %{
               example_format: :line,
               line: 16,
               mutated_ast: {
                 :defmodule,
                 [do: [line: 1], end: [line: 19], line: 1],
                 [
                   {:__aliases__, [{:last, [line: 1]}, {:line, 1}], [:Tester]},
                   [
                     {
                       {:__block__, [line: 1], [:do]},
                       {
                         :__block__,
                         [],
                         [
                           {
                             :defmacrop,
                             [
                               end_of_expression: [newlines: 2, line: 6],
                               do: [line: 2],
                               end: [line: 6],
                               line: 2
                             ],
                             [
                               {:priv_macro, [closing: [line: 2], line: 2],
                                [{:arg, [line: 2], nil}]},
                               [
                                 {
                                   {:__block__, [line: 2], [:do]},
                                   {
                                     :quote,
                                     [do: [line: 3], end: [line: 5], line: 3],
                                     [
                                       [
                                         {
                                           {:__block__, [line: 3], [:do]},
                                           {:priv_fun, [closing: [line: 4], line: 4],
                                            [{:arg, [line: 4], nil}]}
                                         }
                                       ]
                                     ]
                                   }
                                 }
                               ]
                             ]
                           },
                           {
                             :defmacro,
                             [
                               end_of_expression: [newlines: 2, line: 12],
                               do: [line: 8],
                               end: [line: 12],
                               line: 8
                             ],
                             [
                               {:my_macro, [closing: [line: 8], line: 8],
                                [{:arg, [line: 8], nil}]},
                               [
                                 {
                                   {:__block__, [line: 8], [:do]},
                                   {
                                     :quote,
                                     [do: [line: 9], end: [line: 11], line: 9],
                                     [
                                       [
                                         {
                                           {:__block__, [line: 9], [:do]},
                                           {:my_fun, [closing: [line: 10], line: 10],
                                            [{:arg, [line: 10], nil}]}
                                         }
                                       ]
                                     ]
                                   }
                                 }
                               ]
                             ]
                           },
                           {
                             :def,
                             [end_of_expression: [newlines: 2, line: 14], line: 14],
                             [
                               {:my_fun, [closing: [line: 14], line: 14],
                                [{:arg, [line: 14], nil}]},
                               [
                                 {
                                   {:__block__, [{:format, :keyword}, {:line, 14}], [:do]},
                                   {:priv_fun, [closing: [line: 14], line: 14],
                                    [{:arg, [line: 14], nil}]}
                                 }
                               ]
                             ]
                           },
                           {
                             :defp,
                             [do: [line: 16], end: [line: 18], line: 16],
                             [
                               {:random_function, [closing: [line: 16], line: 16],
                                [{:arg, [line: 16], nil}]},
                               [
                                 {
                                   {:__block__, [line: 16], [:do]},
                                   {:+, [line: 17],
                                    [
                                      {:arg, [line: 17], nil},
                                      {:__block__, [token: "1", line: 17], [1]}
                                    ]}
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
    end
  end

  defp name_fun(_), do: "random_function"
end
