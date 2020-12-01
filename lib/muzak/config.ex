defmodule Muzak.Config do
  @moduledoc false

  # Everything around configuration and setup of the application
  #
  # This is like all side effects, so I'm not even going to try and test it, nor should anything
  # else go in this module

  @switches [only: :string]
  @ex_unit_option_keys [:max_failures, :formatters]

  alias Muzak.{Formatter, Mutations}

  @doc false
  # The function to do all our config setup
  def setup(args) do
    opts = get_opts(args)
    Code.put_compiler_option(:ignore_module_conflict, true)
    Formatter.start_link()
    Mix.Task.run("compile", args)
    Mix.Task.run("app.start", args)
    Application.ensure_started(:logger)
    Application.ensure_loaded(:ex_unit)

    {matched_test_files, test_paths, ex_unit_opts} = configure_ex_unit(opts)

    {matched_test_files, test_paths, ex_unit_opts, Mutations.generate_mutations(opts), opts}
  end

  defp get_opts(args) do
    {cli_opts, _} = OptionParser.parse!(args, strict: @switches)

    if path = cli_opts[:only] do
      unless File.exists?(path) do
        raise("file `#{path}` passed as argument to `--only` does not exist")
      end
    end

    debug_config =
      if System.get_env("DEBUG") do
        [formatters: [ExUnit.CLIFormatter]]
      else
        []
      end

    [mutations: 25, autorun: false, max_failures: 1, formatters: []]
    |> Keyword.merge(debug_config)
    |> Keyword.merge(cli_opts)
  end

  defp configure_ex_unit(opts) do
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
