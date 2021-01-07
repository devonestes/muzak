# Muzak

Muzak is a basic mutation testing library for Elixir. It is the limited, open source version of
[Muzak Pro](#muzak-pro). If you're not familiar with mutation testing, you can learn more about
it in the [guide here](why_mutation_testing.md).

## Getting started

To get started with mutation testing, first add `muzak` as a dependency in your `mix.exs` file and
set the `preferred_cli_env` for `muzak` to `test`:

```
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

Muzak will then randomly generate up to 1000 mutations in your application and run your test suite
against each of them. If your application contains more than 1000 possible mutations, then you may
see different results for subsequent runs.

## Configuration

Configuration in Muzak is limited, but you can do quite a bit with it. If you require additional
configuration options, [Muzak Pro](#muzak-pro) will likely meet all those needs.

### CLI Flags

There are several CLI flags that can be passed to modify the behavior of Muzak as needed. CLI
flags will always override any configuration set in `.muzak.exs`.

* `--mutations`: The number of mutations to generate. Example: `mix muzak --mutations 30`
* `--seed`: The seed used for randomization. Example: `mix muzak --seed 976276`
* `--profile`: The profile in `.muzak.exs` to use. Example: `mix muzak --profile ci`
* `--min-coverage`: The minimum percentage (0.0-100/0) of mutations that must be found for a run
    to be considered "passing" and to exit with a 0 status code. Example:
    `mix muzak --min-coverage 85.5`
* `--only`: Restrict mutation generation to a single file or a single line. Examples: `mix muzak
    --only path/to/file.ex` or `mix muzak --only path/to/file.ex:12`

### `.muzak.exs` Configuration File

Most of the time you'll want to save your configuration in a `.muzak.exs` file. In this file,
you can create profiles with different sets of configuration for different uses (such as when
running in CI or locally by a developer). Each of these profiles can contain the following keys:

* `:min_coverage`: The minimum percentage (0.0-100.0) of mutations that must be found for a run
    to be considered "passing" and to exit with a 0 status code. Defaults to `0.0`
* `:mutation_filter`: An arity 1 function used to filter files for mutation generation.
    This function must return a list of tuples, where the first element in the tuple is the
    path to the file, and the second element is `nil` or a list of integers representing line
    numbers. The argument passed to the function is a list of the files in your application as
    set in the `elixirc_paths` key in your Mix project.
      - `{"path/to/file.ex", nil}` will make all possible mutations on all lines in the file.
      - `{"path/to/file.ex", [1, 2, 3]}` will make all possible mutations but only on lines
        1, 2 and 3 in the file.

A `.muzak.exs` file might look something like this:

```
%{
  default: [
    mutation_filter: fn all_project_files ->
      all_project_files
      |> Enum.reject(&String.starts_with?(&1, "test/"))
      |> Enum.filter(&String.ends_with?(&1, ".ex"))
      |> Enum.map(&{&1, nil})
    end
  ],
  ci: [
    mutation_filter: fn all_project_files ->
      all_project_files
      |> Enum.reject(&String.starts_with?(&1, "test/"))
      |> Enum.filter(&String.ends_with?(&1, ".ex"))
      |> Enum.map(&{&1, nil})
    end,
    min_coverage: 85.5
  ]
}
```

## Muzak Pro

Muzak Pro is the full-featured, paid version of Muzak. It includes:

* No limit on the number of generated mutations
* Over a dozen additional mutators
* Far more configuration options
* Parallel execution by spawning multiple BEAM nodes (_experimental_)
* "Analysis Mode" to identify potentially low-value or duplicate tests in your test suite (_coming soon_)
* Enhanced reporting, including HTML reports (_coming soon_)

Muzak Pro costs $29/month, and [is available now](https://devonestes.com/muzak).
