defmodule Muzak do
  @moduledoc false

  def run(args) do
    args
    |> Muzak.Config.setup()
    |> Muzak.Runner.run_test_loop()
    |> Muzak.Formatter.print_report()
  end
end
