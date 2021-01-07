defmodule Muzak.Config do
  @moduledoc false

  # Everything around configuration and setup of the application
  #
  # This is like all side effects, so I'm not even going to try and test it, nor should anything
  # else go in this module

  @switches [
    mutations: :integer,
    seed: :integer,
    only: :string,
    profile: :string,
    min_coverage: :float
  ]
  @ex_unit_option_keys [:include, :seed, :max_failures, :formatters, :exclude, :only]

  alias Muzak.{Formatter, Mutations}

  @doc false
  # The function to do all our config setup
  def setup(args) do
    Application.ensure_started(:logger)
    Mix.Task.run("compile", args)
    Mix.Task.run("app.start", args)
    Application.ensure_loaded(:ex_unit)
    opts = get_opts(args)
    Code.put_compiler_option(:ignore_module_conflict, true)
    Formatter.start_link(opts)

    {matched_test_files, test_paths, ex_unit_opts} = configure_ex_unit(opts)

    {matched_test_files, test_paths, ex_unit_opts, Mutations.generate_mutations(opts), opts}
  end

  defp get_opts(args) do
    {cli_opts, _} = OptionParser.parse!(args, strict: @switches)

    {file_opts, _} =
      if File.exists?(".muzak.exs") do
        Code.eval_file(".muzak.exs")
      else
        {%{default: []}, nil}
      end

    file_opts =
      case cli_opts[:profile] do
        nil -> Map.get(file_opts, :default)
        profile -> Map.get(file_opts, String.to_atom(profile))
      end

    seed =
      0..9
      |> Stream.cycle()
      |> Enum.take(600)
      |> Enum.take_random(6)
      |> Enum.join()
      |> String.to_integer()

    debug_config =
      if System.get_env("DEBUG") do
        [formatters: [ExUnit.CLIFormatter]]
      else
        [formatters: []]
      end

    opts =
      [
        mutations: 1_000,
        autorun: false,
        max_failures: 1,
        seed: seed
      ]
      |> Keyword.merge(debug_config)
      |> Keyword.merge(file_opts)
      |> Keyword.merge(cli_opts)

    if Keyword.has_key?(opts, :only) do
      only = opts[:only]

      {file, line} =
        case String.split(only, ":") do
          [file, line] -> {file, [String.to_integer(line)]}
          _ -> {only, nil}
        end

      unless File.exists?(file) do
        raise("file `#{file}` passed as argument to `--only` does not exist")
      end

      Keyword.put(opts, :mutation_filter, fn _ -> [{file, line}] end)
    else
      opts
    end
  end

  def configure_ex_unit(opts) do
    shell = Mix.shell()
    project = Mix.Project.config()
    test_paths = project[:test_paths] || default_test_paths()
    test_pattern = project[:test_pattern] || "*_test.exs"
    ex_unit_opts = Keyword.take(opts, @ex_unit_option_keys)

    ExUnit.configure(ex_unit_opts)
    Enum.each(test_paths, &require_test_helper(shell, &1))
    ExUnit.configure(ex_unit_opts)

    {Mix.Utils.extract_files(test_paths, test_pattern), test_paths, ex_unit_opts}
  end

  defp require_test_helper(shell, dir) do
    file = Path.join(dir, "test_helper.exs")

    if File.exists?(file) do
      Code.unrequire_files([file])
      Code.require_file(file)
    else
      Mix.shell(shell)
      Mix.raise("Cannot run tests because test helper file #{inspect(file)} does not exist")
    end
  end

  defp default_test_paths do
    if File.dir?("test") do
      ["test"]
    else
      []
    end
  end
end
