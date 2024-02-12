defmodule RDF.Mixfile do
  use Mix.Project

  @scm_url "https://github.com/rdf-elixir/rdf-ex"

  @version File.read!("VERSION") |> String.trim()

  def project do
    [
      app: :rdf,
      version: @version,
      elixir: "~> 1.11",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:leex, :yecc] ++ Mix.compilers() ++ [:protocol_ex],
      aliases: aliases(),

      # Dialyzer
      dialyzer: dialyzer(),

      # Hex
      package: package(),
      description: description(),

      # Docs
      name: "RDF.ex",
      docs: [
        main: "RDF",
        source_url: @scm_url,
        source_ref: "v#{@version}",
        extras: ["CHANGELOG.md"]
      ],

      # ExCoveralls
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        check: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        earl_reports: :test
      ]
    ]
  end

  defp description do
    """
    An implementation of RDF for Elixir.
    """
  end

  defp package do
    [
      maintainers: ["Marcel Otto"],
      licenses: ["MIT"],
      links: %{
        "Homepage" => "https://rdf-elixir.dev",
        "GitHub" => @scm_url,
        "Changelog" => @scm_url <> "/blob/master/CHANGELOG.md"
      },
      files: ~w[lib src/*.xrl src/*.yrl priv mix.exs .formatter.exs VERSION *.md]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:decimal, "~> 1.5 or ~> 2.0"},
      {:protocol_ex, "~> 0.4.4"},
      {:elixir_uuid, "~> 1.2", optional: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      # This dependency is needed for ExCoveralls when OTP < 25
      {:castore, "~> 1.0", only: :test},
      {:benchee, "~> 1.3", only: :bench}
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      ignore_warnings: ".dialyzer_ignore.exs",
      # Error out when an ignore rule is no longer useful so we can remove it
      list_unused_filters: true
    ]
  end

  defp aliases do
    [
      earl_reports: &earl_reports/1,
      check: [
        "clean",
        "deps.unlock --check-unused",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "deps.unlock --check-unused",
        "test --warnings-as-errors",
        "credo"
      ]
    ]
  end

  defp earl_reports(_) do
    files = [
      "test/acceptance/ntriples_w3c_test.exs",
      "test/acceptance/ntriples_star_w3c_test.exs",
      "test/acceptance/nquads_w3c_test.exs",
      "test/acceptance/turtle_w3c_test.exs",
      "test/acceptance/turtle_star_w3c_syntax_test.exs",
      "test/acceptance/turtle_star_w3c_eval_test.exs",
      "test/acceptance/canonicalization_w3c_test.exs"
    ]

    Mix.Task.run("test", ["--formatter", "EarlFormatter", "--seed", "0"] ++ files)
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
