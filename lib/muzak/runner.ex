defmodule Muzak.Runner do
  @moduledoc false

  # All the code to actually run the tests and such

  alias Muzak.{Config, Formatter}

  @doc false
  def run_test_loop({_, _, _, mutations, opts} = test_info, runner \\ &require_and_run/1) do
    num_mutations = length(mutations)

    IO.puts("Beginning mutation testing - #{num_mutations} mutations generated\n")

    start = System.monotonic_time(:microsecond)

    results =
      mutations
      |> Enum.with_index()
      |> Enum.reduce([], fn {mutation, idx}, acc ->
        print("Running mutation #{idx + 1} of #{num_mutations}")

        mutation
        |> run_mutation(test_info, runner, opts)
        |> handle_result(acc)
      end)

    finish_time = System.monotonic_time(:microsecond) - start

    success_percentage =
      if num_mutations > 0 do
        num_failures = length(results)
        success_percentage = Float.round((1 - num_failures / num_mutations) * 100, 2)

        if success_percentage < Keyword.get(opts, :min_coverage, 100.0) do
          System.at_exit(fn _ -> exit({:shutdown, 1}) end)
        end

        success_percentage
      else
        100.0
      end

    {results, num_mutations, finish_time, success_percentage, opts}
  end

  @doc false
  defp run_mutation(mutation_info, test_info, runner, opts) do
    restart_apps(opts)

    fn ->
      cleanup_processes()

      print("""

      Starting mutation at #{mutation_info.path}:#{mutation_info.line}

      <<<<<<< ORIGINAL
      #{mutation_info.original}
      =======
      #{mutation_info.mutation}
      >>>>>>> MUTATION

      """)

      results =
        with :ok <- compile_mutation(mutation_info),
             :ok <- compile_dependencies(mutation_info) do
          run_tests(mutation_info, test_info, runner)
        end

      recompile_original(mutation_info.original_file)
      {results, mutation_info}
    end
    |> run_silent()
    |> print_result()
  end

  @apps_to_keep [
    # OTP basic apps

    :compiler,
    :erts,
    :kernel,
    :sasl,
    :stdlib,
    :os_mon,
    :asn1,
    :crypto,
    :diameter,
    :eldap,
    :erl_interface,
    :ftp,
    :inets,
    :jinterface,
    :megaco,
    :public_key,
    :ssh,
    :ssl,
    :tftp,
    :wx,
    :xmerl,
    :logger,
    :parsetools,
    :runtime_tools,
    :hipe,

    # Elixir basic apps

    :elixir,
    :mix,
    :hex,
    :muzak
  ]

  defp restart_apps(opts) do
    Application.stop(Mix.Project.config()[:app])

    apps_to_keep =
      if System.get_env("MUZAK_TESTS") do
        @apps_to_keep ++ [:ex_unit]
      else
        @apps_to_keep
      end

    for {dep, _, _} <- Application.started_applications(), dep not in apps_to_keep do
      Application.stop(dep)
    end

    Mix.Task.reenable("app.start")
    Mix.Task.run("app.start")

    unless System.get_env("MUZAK_TESTS") do
      Config.configure_ex_unit(opts)
      Application.ensure_started(:ex_unit)
    end
  end

  defp cleanup_processes() do
    Code.purge_compiler_modules()

    # This is a really weird hack because some files were stuck as being already required, and so
    # we entered the compilation queue but never actually made it out of the queue.
    #
    # We should ask Jose what's going on here and how to _not_ do this.
    :sys.replace_state(:elixir_code_server, &put_elem(&1, 1, %{}))

    # We also need to update the ExUnit.Server, which I would love to not have to do, but looks
    # like we need to.
    :sys.replace_state(ExUnit.Server, fn _ ->
      %{
        async_modules: [],
        loaded: System.monotonic_time(),
        sync_modules: [],
        waiting: nil
      }
    end)

    for pid <- Process.list(),
        [links: [], monitors: [], dictionary: dict] <- [
          Process.info(pid, [:links, :monitors, :dictionary])
        ] do
      case {Keyword.get(dict, :"$initial_call"), Keyword.get(dict, :elixir_compiler_pid)} do
        # When the compiler has an error it can orphan processes, so we're cleaning them up here
        {_, compiler_pid} when is_pid(compiler_pid) ->
          Process.exit(pid, :kill)

        # When ExUnit finishes, it leaves some processes orphaned, so we're cleaning them up
        # here before we begin again
        {{_, f, _}, _} ->
          if f |> Atom.to_string() |> String.starts_with?("-test") do
            Process.exit(pid, :kill)
          end

        _ ->
          :ok
      end
    end
  end

  defp print_result({{:ok, %{failures: 0, total: total}}, _} = result) when total > 0 do
    print(:failure)
    result
  end

  defp print_result(result) do
    print(:success)
    result
  end

  defp handle_result({{:ok, %{failures: 0, total: t}}, info}, acc) when t > 0, do: [info | acc]
  defp handle_result(_, acc), do: acc

  defp compile_mutation(mutation_info) do
    print(:"Mutating file")

    try do
      if hd(mutation_info.original) == "defmodule" do
        [_, _ | module_info] = mutation_info.original
        [_ | module_info] = Enum.reverse(module_info)
        module = (module_info ++ ["Elixir"]) |> Enum.reverse() |> Module.concat()

        path =
          Enum.find_value(:code.all_loaded(), fn {mod, path} ->
            if mod == module do
              path
            end
          end)

        :code.purge(module)
        :code.delete(module)
        File.rm!(path)
      end

      Code.compile_string(mutation_info.file)
      print(:"Mutating completed")
      :ok
    rescue
      _ ->
        print(:"Mutation failed to compile")
        :compilation_error
    end
  end

  defp compile_dependencies(mutation_info) do
    try do
      sources =
        Mix.Project.manifest_path()
        |> Path.join("compile.elixir")
        |> File.read!()
        |> :erlang.binary_to_term()
        |> case do
          {_, _, sources} -> sources
          {_, _, sources, _} -> sources
        end

      sources
      |> Enum.find_value(fn {_, path, _, _, _, _, _, _, _, modules} ->
        if path == mutation_info.path, do: modules, else: false
      end)
      |> case do
        [] ->
          print(:"No modules defined in file")

        [_ | _] = modules_defined ->
          sources
          |> Enum.reduce([], fn {_, path, _, module_dependencies, _, _, _, _, _, _}, acc ->
            if Enum.any?(module_dependencies, &(&1 in modules_defined)),
              do: [path | acc],
              else: acc
          end)
          |> case do
            [] ->
              print(:"No dependencies of mutated file to compile")
              :ok

            paths ->
              print(:"Compiling dependencies of mutated file")
              Enum.each(paths, &Code.compile_file/1)
              print(:"Compiling dependencies of mutated file completed")
              :ok
          end

        _ ->
          :ok
      end
    rescue
      _ ->
        print(:"Compiling dependencies of mutated file failed")
        :compilation_error
    end
  end

  defp run_tests(_, {test_files, _, _, _, _}, runner) do
    print(:"Tests starting")
    parent = self()
    spawn(fn -> send(parent, {:__muzak_test_run_results, runner.(test_files)}) end)

    receive do
      {:__muzak_test_run_results, results} ->
        print(:"Tests finished")
        results
    end
  end

  defp require_and_run(matched_test_files) do
    task = ExUnit.async_run()

    try do
      case Kernel.ParallelCompiler.require(matched_test_files, []) do
        {:ok, _, _} ->
          ExUnit.Server.modules_loaded()
          {:ok, ExUnit.await_run(task)}

        {:error, _, _} ->
          Task.shutdown(task, :brutal_kill)
          {:ok, :compile_error}
      end
    catch
      _, _ ->
        Task.shutdown(task, :brutal_kill)
        {:ok, :compile_error}
    end
  end

  defp recompile_original(original_file) do
    Code.compile_string(original_file)
    print(:"Original file compiled")

    Code.unrequire_files(Code.required_files())
    print(:"Files unrequired")
  end

  defp run_silent(function) do
    if System.get_env("DEBUG") do
      function.()
    else
      me = self()

      ExUnit.CaptureLog.capture_log(fn ->
        ExUnit.CaptureIO.capture_io(:standard_io, fn ->
          ExUnit.CaptureIO.capture_io(:standard_error, fn ->
            send(me, function.())
          end)
        end)
      end)

      receive do
        response -> response
      end
    end
  end

  defp print(msg) do
    send(Formatter, {msg, node()})
  end
end
