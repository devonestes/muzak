defmodule Muzak.RunnerTest do
  use ExUnit.Case

  alias Muzak.Runner

  defmodule SuccessCompiler do
    def require_and_run(matched_test_files) do
      send(Application.get_env(:muzak, :test_pid), {:require_and_run, matched_test_files})
      {:ok, %{failures: 1, total: 1}}
    end
  end

  defmodule FailureCompiler do
    def require_and_run(matched_test_files) do
      send(Application.get_env(:muzak, :test_pid), {:require_and_run, matched_test_files})
      {:ok, %{failures: 0, total: 1}}
    end
  end

  defmodule Formatter do
    def start_link(test_pid) do
      pid = spawn(fn -> receive_loop(test_pid) end)
      Process.register(pid, Muzak.Formatter)
      {:ok, pid}
    end

    def receive_loop(test_pid) do
      receive do
        msg ->
          send(test_pid, {__MODULE__, msg})
          receive_loop(test_pid)
      end
    end

    def child_spec(_) do
      %{
        id: __MODULE__,
        start: {__MODULE__, :start_link, [self()]},
        type: :worker,
        restart: :temporary,
        shutdown: 500
      }
    end
  end

  setup do
    formatter = Process.whereis(Muzak.Formatter)
    System.put_env("DEBUG", "1")
    Application.put_env(:muzak, :test_pid, self())

    on_exit(fn ->
      if is_pid(formatter) do
        Process.register(formatter, Muzak.Formatter)
      end

      System.delete_env("DEBUG")
    end)

    start_supervised!(Formatter)

    :ok
  end

  describe "run_test_loop/1" do
    test "doesn't run tests if the mutation can't compile" do
      test_files = [:a, :b]
      test_paths = [:c, :d]
      opts = [:e, :f]
      mutations = [%{original_file: "{1, 2}", file: "{1, 2"}]
      test_info = {test_files, test_paths, opts, mutations, []}

      assert {[], 1, num, []} = Runner.run_test_loop(test_info, &SuccessCompiler.require_and_run/1)
      assert num > 1

      assert_receive {Formatter, {"Mutating file", :nonode@nohost}}
      assert_receive {Formatter, {"Mutation failed to compile", :nonode@nohost}}
      assert_receive {Formatter, {"Original file compiled", :nonode@nohost}}
      assert_receive {Formatter, {"Files unrequired", :nonode@nohost}}
      assert_receive {Formatter, {:success, :nonode@nohost}}
      refute_receive _
    end

    test "calls the ExUnit compiler correctly when the file can be compiled" do
      test_files = [:a, :b]
      test_paths = [:c, :d]
      opts = [:e, :f]
      mutations = [%{original_file: "{1, 2, 3}", file: "{3, 2, 1}", line: 1}]
      test_info = {test_files, test_paths, opts, mutations, []}

      assert {[], 1, num, []} = Runner.run_test_loop(test_info, &SuccessCompiler.require_and_run/1)
      assert num > 1

      assert_receive {Formatter, {"Mutating file", :nonode@nohost}}
      assert_receive {Formatter, {"Mutating completed", :nonode@nohost}}
      assert_receive {Formatter, {"Tests starting", :nonode@nohost}}
      assert_receive {:require_and_run, ^test_files}
      assert_receive {Formatter, {"Tests finished", :nonode@nohost}}
      assert_receive {Formatter, {"Original file compiled", :nonode@nohost}}
      assert_receive {Formatter, {"Files unrequired", :nonode@nohost}}
      assert_receive {Formatter, {:success, :nonode@nohost}}
      refute_receive _
    end

    test "sends the right messages when there is a failure" do
      test_files = [:a, :b]
      test_paths = [:c, :d]
      opts = [:e, :f]
      mutations = [%{original_file: "{1, 2, 3}", file: "{3, 2, 1}", line: 1}]
      test_info = {test_files, test_paths, opts, mutations, []}

      assert {^mutations, 1, num, []} = Runner.run_test_loop(test_info, &FailureCompiler.require_and_run/1)
      assert num > 1

      assert_receive {Formatter, {"Mutating file", :nonode@nohost}}
      assert_receive {Formatter, {"Mutating completed", :nonode@nohost}}
      assert_receive {Formatter, {"Tests starting", :nonode@nohost}}
      assert_receive {:require_and_run, ^test_files}
      assert_receive {Formatter, {"Tests finished", :nonode@nohost}}
      assert_receive {Formatter, {"Original file compiled", :nonode@nohost}}
      assert_receive {Formatter, {"Files unrequired", :nonode@nohost}}
      assert_receive {Formatter, {:failure, :nonode@nohost}}
      refute_receive _
    end
  end
end
