defmodule RDF.Mixfile do
  use Mix.Project

  @scm_url "https://github.com/rdf-elixir/rdf-ex"

  @version File.read!("VERSION") |> String.trim()

  def project do
    [
      app: :rdf,
      version: @version,
      elixir: "~> 1.14",
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
      docs: docs(),

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
      {:decimal, "~> 2.0"},
      {:uniq, "~> 0.6"},
      {:jason, "~> 1.4"},
      {:jcs, "~> 0.2"},
      {:protocol_ex, "~> 0.4.4"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.37", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      # This dependency is needed for ExCoveralls when OTP < 25
      {:castore, "~> 1.0", only: :test},
      {:benchee, "~> 1.3", only: :dev}
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
      "test/acceptance/nquads_star_w3c_test.exs",
      "test/acceptance/turtle_w3c_test.exs",
      "test/acceptance/turtle_star_w3c_syntax_test.exs",
      "test/acceptance/turtle_star_w3c_eval_test.exs",
      "test/acceptance/trig_w3c_test.exs",
      "test/acceptance/trig_star_w3c_syntax_test.exs",
      "test/acceptance/trig_star_w3c_eval_test.exs",
      "test/acceptance/canonicalization_w3c_test.exs"
    ]

    Mix.Task.run("test", ["--formatter", "RDF.Test.EarlFormatter", "--seed", "0"] ++ files)
  end

  defp docs do
    [
      main: "RDF",
      source_url: @scm_url,
      source_ref: "v#{@version}",
      extras: [
        {:"README.md", [title: "About"]},
        {:"CHANGELOG.md", [title: "CHANGELOG"]},
        {:"CONTRIBUTING.md", [title: "CONTRIBUTING"]},
        {:"LICENSE.md", [title: "License"]}
      ],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      groups_for_modules: [
        Terms: [
          RDF.Term,
          RDF.Resource,
          RDF.Literal,
          RDF.IRI,
          RDF.BlankNode,
          RDF.Sigils
        ],
        Structures: [
          RDF.Statement,
          RDF.Triple,
          RDF.Quad,
          RDF.Description,
          RDF.Graph,
          RDF.Dataset,
          RDF.Data,
          RDF.List,
          RDF.Diff,
          RDF.PrefixMap,
          RDF.PropertyMap
        ],
        Namespace: [
          RDF.Namespace,
          RDF.Namespace.IRI,
          RDF.Vocabulary,
          RDF.Vocabulary.Namespace
        ],
        "Predefined namespaces": [
          RDF.NS,
          RDF.NS.RDF,
          RDF.NS.RDFS,
          RDF.NS.OWL,
          RDF.NS.SKOS,
          RDF.NS.XSD
        ],
        "Predefined datatypes": [
          RDF.LangString,
          RDF.JSON,
          RDF.Literal.Generic,
          RDF.XSD.String,
          RDF.XSD.Boolean,
          RDF.XSD.Numeric,
          RDF.XSD.Float,
          RDF.XSD.Double,
          RDF.XSD.Decimal,
          RDF.XSD.Integer,
          RDF.XSD.Long,
          RDF.XSD.Int,
          RDF.XSD.Short,
          RDF.XSD.Byte,
          RDF.XSD.NonPositiveInteger,
          RDF.XSD.NegativeInteger,
          RDF.XSD.NonNegativeInteger,
          RDF.XSD.PositiveInteger,
          RDF.XSD.UnsignedLong,
          RDF.XSD.UnsignedInt,
          RDF.XSD.UnsignedShort,
          RDF.XSD.UnsignedByte,
          RDF.XSD.DateTime,
          RDF.XSD.Date,
          RDF.XSD.Time,
          RDF.XSD.Base64Binary,
          RDF.XSD.AnyURI
        ],
        "Datatype system": [
          RDF.Literal.Datatype,
          RDF.Literal.Datatype.Registry,
          RDF.XSD,
          RDF.XSD.Datatype,
          RDF.XSD.Datatype.Primitive,
          RDF.XSD.Datatype.Restriction,
          RDF.XSD.Facet,
          RDF.XSD.Facets.ExplicitTimezone,
          RDF.XSD.Facets.FractionDigits,
          RDF.XSD.Facets.Length,
          RDF.XSD.Facets.MaxExclusive,
          RDF.XSD.Facets.MaxInclusive,
          RDF.XSD.Facets.MaxLength,
          RDF.XSD.Facets.MinExclusive,
          RDF.XSD.Facets.MinInclusive,
          RDF.XSD.Facets.MinLength,
          RDF.XSD.Facets.Pattern,
          RDF.XSD.Facets.TotalDigits
        ],
        "Resource generators": [
          RDF.Resource.Generator,
          RDF.IRI.UUID.Generator,
          RDF.BlankNode.Generator,
          RDF.BlankNode.Generator.Algorithm,
          RDF.BlankNode.Generator.UUID,
          RDF.BlankNode.Generator.Increment,
          RDF.BlankNode.Generator.Random
        ],
        Serialization: [
          RDF.Serialization,
          RDF.Serialization.Decoder,
          RDF.Serialization.Encoder,
          RDF.Serialization.Format,
          RDF.NTriples,
          RDF.NTriples.Decoder,
          RDF.NTriples.Encoder,
          RDF.NQuads,
          RDF.NQuads.Decoder,
          RDF.NQuads.Encoder,
          RDF.Turtle,
          RDF.Turtle.Decoder,
          RDF.Turtle.Encoder,
          RDF.TriG,
          RDF.TriG.Decoder,
          RDF.TriG.Encoder
        ],
        "Query engine": [
          RDF.Query,
          RDF.Query.BGP
        ],
        Canonicalization: [
          RDF.Canonicalization,
          RDF.Canonicalization.State,
          RDF.Canonicalization.IdentifierIssuer
        ],
        "RDF-star": [
          RDF.Star.Triple,
          RDF.Star.Quad,
          RDF.Star.Statement
        ],
        Test: [
          RDF.Test.Assertions,
          RDF.Test.EarlFormatter
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
