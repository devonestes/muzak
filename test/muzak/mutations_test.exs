defmodule Muzak.MutationsTest do
  use Assertions.Case, async: true

  alias Muzak.{Mutations, Mutators.Functions.Rename, Mutators.Constants.Numbers}

  describe "mutate_file/2" do
    test "applies all possible mutations to the given file for the given mutators" do
      file = """
      defmodule TestModule do
        def test_fun(var) do
          var == :ok
        end
      end
      """

      expected = %{
        file:
          String.trim_trailing("""
          defmodule TestModule do
            def randomatom(var) do
              var == :ok
            end
          end
          """),
        line: 2,
        original: ["def", " ", "test_fun", "(", "", "var", "", ")", " do"],
        mutation: ["def", " ", "randomatom", "(", "", "var", "", ")", " do"],
        original_file: file,
        path: "path/to/file.ex"
      }

      {file, "path/to/file.ex"}
      |> Mutations.mutate_file([Rename], fn _ -> "randomatom" end)
      |> assert_lists_equal([expected])
    end

    test "returns multiple mutations on a single line" do
      file = """
      defmodule TestModule do
        def test_fun(var) do
          var in [1, 2]
        end
      end
      """

      expected1 = %{
        file:
          String.trim_trailing("""
          defmodule TestModule do
            def test_fun(var) do
              var in [32_780, 2]
            end
          end
          """),
        line: 3,
        mutation: ["var", " in ", "[", "", "32_780", ",", " ", "2", "", "]"],
        original: ["var", " in ", "[", "", "1", ",", " ", "2", "", "]"],
        original_file: file,
        path: "path/to/file.ex"
      }

      expected2 = %{
        file:
          String.trim_trailing("""
          defmodule TestModule do
            def test_fun(var) do
              var in [1, 32_781]
            end
          end
          """),
        line: 3,
        mutation: ["var", " in ", "[", "", "1", ",", " ", "32_781", "", "]"],
        original: ["var", " in ", "[", "", "1", ",", " ", "2", "", "]"],
        original_file: file,
        path: "path/to/file.ex"
      }

      {file, "path/to/file.ex"}
      |> Mutations.mutate_file([Numbers], &name_fun/1)
      |> assert_lists_equal([expected1, expected2])
    end
  end

  defp name_fun(_), do: 32_779
end
