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

Muzak will then randomly generate 25 mutations in your application and run your test suite against
each of them. Each time you run `mix muzak` you will see different results.

## Configuration

Configuration in Muzak is limited, but you can limit the mutations generated to a single file by
using `mix muzak --only path/to/file.ex`. The limit of 25 mutations still exists, but this gives
you some control over what is mutated so you can focus your testing on a single file.

If you require additional configuration options, [Muzak Pro](#muzak-pro) will likely meet all
those needs.

## Muzak Pro

Muzak Pro is the full-featured, paid version of Muzak. It includes:

* No limit on the number of generated mutations
* Over a dozen additional mutators
* `git` integration to make mutation testing in CI blazing fast
* Far more configuration options at the command line and with a `.muzak.exs` file
* Extensive documentation to help you get the most value possible out of mutation testing
* Parallel execution by spawning multiple BEAM nodes (_experimental_)
* "Analysis Mode" to identify potentially low-value or duplicate tests in your test suite (_coming soon_)
* Enhanced reporting, including HTML reports (_coming soon_)

Muzak Pro costs $29/month, and [is available now](https://devonestes.com/muzak).
