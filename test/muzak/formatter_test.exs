defmodule Muzak.FormatterTest do
  use ExUnit.Case, async: true

  alias Muzak.Formatter

  alias ExUnit.CaptureIO

  describe "do_print_report/1" do
    test "prints the right thing for a :noop" do
      assert CaptureIO.capture_io(fn ->
               Formatter.do_print_report({:noop, 123, 123_000, [seed: 632_719]})
             end) == """


             Finished in 0.1 seconds
             Something went wrong - tests did not run for a later set of mutations!

             """
    end

    test "prints the right thing for :no_tests_run" do
      assert CaptureIO.capture_io(fn ->
               Formatter.do_print_report({:no_tests_run, 123, 123_000, [seed: 632_719]})
             end) == """


             Finished in 0.1 seconds
             Something went wrong - no tests were selected to be run!

             """
    end

    test "prints the right thing for successful cases" do
      assert CaptureIO.capture_io(fn ->
               Formatter.do_print_report({[], 123, 123_000, [seed: 632_719]})
             end) == """


             Finished in 0.1 seconds
             \e[32m123 run - 0 mutations survived\e[0m
             """
    end

    test "prints the right thing for failures cases" do
      line1 = ["def", " ", "test_fun", "(", "", "var", "", ")", " do"]
      line2 = ["  ", "var", " ==", " ", ":ok"]
      line3 = ["", "end"]
      mutation = ["  ", "raise", " ", "\"", "Exception introduced by Muzak", "\""]

      original = line1 ++ ["\n"] ++ line2 ++ ["\n"] ++ line3
      mutation = line1 ++ ["\n"] ++ mutation ++ ["\n"] ++ line2 ++ ["\n"] ++ line3

      failures = [
        %{
          line: 72,
          original: ["if", " ", "var", " ==", " ", ":ok"],
          mutation: ["if", " ", "var", " !=", " ", ":ok"],
          path: "path/to/file.ex"
        },
        %{
          line: 81,
          original: ["if", " ", "var", " ==", " ", ":ok"],
          mutation: ["if", " ", "var", " ==", " ", ":error"],
          path: "path/to/file.ex"
        },
        %{
          line: 87,
          original: ["{", "", ":ok", ",", " response", "}", " ", "->"],
          mutation: ["{", "", ":error", ",", " response", "}", " ", "->"],
          path: "path/to/other/file.ex"
        },
        %{
          line: 90,
          original: ["{", "", ":ok", ",", " ", "\"", "thing", "\"", "}", " ", "->"],
          mutation: ["{", "", ":ok", ",", " ", "\"", "random_string", "\"", "}", " ", "->"],
          path: "path/to/other/file.ex"
        },
        %{
          line: 99,
          original: original,
          mutation: mutation,
          path: "path/to/other/file.ex"
        }
      ]

      first =
        String.trim("""
        \e[31mpath/to/file.ex:72\e[0m
             \e[36moriginal: \e[0mif var =\e[32m=\e[0m :ok
             \e[36mmutation: \e[0mif var \e[31m!\e[0m= :ok
        """)

      second =
        String.trim("""
        \e[31mpath/to/file.ex:81\e[0m
             \e[36moriginal: \e[0mif var == \e[32m:ok\e[0m
             \e[36mmutation: \e[0mif var == \e[31m:error\e[0m
        """)

      third =
        String.trim("""
        \e[31mpath/to/other/file.ex:87\e[0m
             \e[36moriginal: \e[0m{\e[32m:ok\e[0m, response} ->
             \e[36mmutation: \e[0m{\e[31m:error\e[0m, response} ->
        """)

      fourth =
        String.trim("""
        \e[31mpath/to/other/file.ex:90\e[0m
             \e[36moriginal: \e[0m{:ok, \"\e[32mthing\e[0m\"} ->
             \e[36mmutation: \e[0m{:ok, \"\e[31mrandom_string\e[0m\"} ->
        """)

      fifth =
        String.trim("""
        \e[31mpath/to/other/file.ex:99\e[0m
             \e[36moriginal: \e[0mdef test_fun(var) do
                         var == :ok
                       end
             \e[36mmutation: \e[0mdef test_fun(var) do
                         \e[31mraise "Exception introduced by Muzak"
                         \e[0mvar == :ok
                       end
        """)

      summary =
        String.trim("""
        Finished in 0.1 seconds
        \e[31m123 mutations run - 5 mutations survived\e[0m
        """)

      assert CaptureIO.capture_io(fn ->
               Formatter.do_print_report({failures, 123, 123_000, [seed: 632_719]})
             end) == """


                  #{first}

                  #{second}

                  #{third}

                  #{fourth}

                  #{fifth}


             #{summary}
             """
    end
  end
end
