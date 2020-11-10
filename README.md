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
      {:muzak, "~> 1.0", only: :test}
    ]
  end
end
```

You're now ready to get started!

```bash
$ mix deps.get
$ mix muzak
```

Muzak will then randomly generate 25 mutations in your application and run your test suite against
each of them. Each time you run `mix muzak` you will see different results.
