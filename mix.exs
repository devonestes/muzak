defmodule Muzak.MixProject do
  use Mix.Project

  @version "1.0.3"

  @source_url "https://github.com/devonestes/muzak"
  @homepage_url "https://devonestes.com/muzak"

  def project do
    [
      app: :muzak,
      description: "Mutation testing for Elixir",
      elixir: "~> 1.10",
      version: @version,
      source_url: @source_url,
      homepage_url: @homepage_url,
      elixirc_paths: ["lib"],
      start_permanent: false,
      deps: [{:assertions, ">= 0.0.0", only: :test}, {:ex_doc, ">= 0.0.0", only: :dev}],
      docs: docs(),
      package: [
        maintainers: ["Devon Estes"],
        licenses: ["CC-BY-NC-ND-4.0"],
        links: %{
          "GitHub" => @source_url,
          "Website" => @homepage_url
        },
        files: ["lib", "mix.exs", "LICENSE"]
      ]
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp docs() do
    [
      main: "muzak",
      api_reference: false,
      source_ref: @version,
      extras: [
        "docs/muzak.md": [filename: "muzak", title: "Muzak"],
        "docs/mutators.md": [filename: "mutators", title: "Included mutators"],
        "docs/why_mutation_testing.md": [
          filename: "what_is_mutation_testing",
          title: "What is mutation testing?"
        ]
      ],
      authors: ["Devon Estes"]
    ]
  end
end
