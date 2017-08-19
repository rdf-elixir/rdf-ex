defmodule RDF.Mixfile do
  use Mix.Project

  @repo_url "https://github.com/marcelotto/rdf-ex"

  @version File.read!("VERSION") |> String.trim

  def project do
    [
      app: :rdf,
      version: @version,
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),

      # Hex
      package: package(),
      description: description(),

      # Docs
      name: "RDF.ex",
      docs: [
        main: "RDF",
        source_url: @repo_url,
        source_ref: "v#{@version}",
        extras: ["README.md"],
      ],

      # ExCoveralls
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
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
      links: %{"GitHub" => @repo_url},
      files: ~w[lib src priv mix.exs README.md LICENSE.md VERSION]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:dialyxir, "~> 0.4",       only: [:dev, :test], runtime: false},
      {:credo, "~> 0.6",          only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.14",        only: :dev, runtime: false},
      {:mix_test_watch, "~> 0.3", only: :dev, runtime: false},
      {:excoveralls, "~> 0.7",    only: :test},
      {:inch_ex, "~> 0.5",        only: [:dev, :test]},
      {:benchee, "~> 0.9",        only: :bench},
      {:erlang_term, "~> 1.7",    only: :bench},
    ]
  end
end
