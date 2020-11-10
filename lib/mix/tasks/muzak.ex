defmodule Mix.Tasks.Muzak do
  @moduledoc false

  @shortdoc "Run mutation tests"
  use Mix.Task

  @preferred_cli_env :test

  @impl true
  def run(args) do
    Muzak.run(args)
  end
end
