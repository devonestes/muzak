defmodule Muzak.Runner do
  @moduledoc false
  # All the code to actually run the tests and such

  alias Muzak.Formatter

  @doc false
  def run_test_loop({_, _, _, mutations, opts} = test_info, runner \\ &require_and_run/1) do
    start = System.monotonic_time(:microsecond)

    results =
        Enum.reduce(mutations, [], fn mutation, acc ->
          mutation
          |> run_mutation(test_info, runner)
          |> handle_result(acc)
        end)

    finish_time = System.monotonic_time(:microsecond) - start

    {results, length(mutations), finish_time, opts}
  end

  @doc false
  def run_mutation(mutation_info, test_info, runner) do
    fn ->
      results =
        with :ok <- compile_mutation(mutation_info) do
          run_tests(test_info, runner)
        end

      recompile_original(mutation_info.original_file)
      cleanup_processes()
      {results, mutation_info}
    end
    |> run_silent()
    |> print_result()
  end

  defp cleanup_processes() do
    Code.purge_compiler_modules()

    # This is a really weird hack because some files were stuck as being already required, and so
    # we entered the compilation queue but never actually made it out of the queue.
    #
    # We should ask Jose what's going on here and how to _not_ do this.
    :sys.replace_state(:elixir_code_server, fn
      {first, _, third, fourth, fifth} -> {first, %{}, third, fourth, fifth}
      state -> state
    end)

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
    print("Mutating file")

    try do
      Code.compile_string(mutation_info.file)
      print("Mutating completed")
      :ok
    rescue
      _ ->
        print("Mutation failed to compile")
        :compilation_error
    end
  end

  defp run_tests({matched_test_files, _, _, _, _}, runner) do
    print("Tests starting")

    parent = self()

    spawn(fn -> send(parent, {:results, runner.(matched_test_files)}) end)

    response =
      receive do
        {:results, results} -> results
      end

    print("Tests finished")
    response
  end

  defp require_and_run(matched_test_files) do
    task = Task.async(ExUnit, :run, [])

    try do
      case Kernel.ParallelCompiler.require(matched_test_files, []) do
        {:ok, _, _} ->
          ExUnit.Server.modules_loaded()
          {:ok, Task.await(task, :infinity)}

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
    print("Original file compiled")

    Code.unrequire_files(Code.required_files())
    print("Files unrequired")
  end

  defp run_silent(function) do
    if System.get_env("DEBUG") do
      function.()
    else
      me = self()

      ExUnit.CaptureLog.capture_log(fn ->
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          ExUnit.CaptureIO.capture_io(:stdio, fn ->
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
