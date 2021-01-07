# Muzak

Mutation testing for Elixir!

## Getting Started

To get started with mutation testing, first add `muzak` as a dependency in your `mix.exs` file and
set the `preferred_cli_env` for `muzak` to `test`:

```elixir
defmodule MyApp.Mixfile do
  def project do
    [
      # ...
      preferred_cli_env: [muzak: :test]
    ]
  end

  # ...

  defp deps do
    [
      # ...
      {:muzak, "~> 1.1", only: :test}
    ]
  end
end
```

You're now ready to get started!

```bash
$ mix deps.get
$ mix muzak
```

Muzak will then randomly generate up to 1000 mutations in your application and run your test suite
against each of them. If your application contains more than 1000 possible mutations, then you may
see different results for subsequent runs.
