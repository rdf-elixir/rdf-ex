defmodule RDF.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :rdf,
      version: @version,
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  defp description do
    """
    An implementation of RDF for Elixir.
    """
  end

  defp package do
    [
      name: :rdf,
      maintainers: ["Marcel Otto"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/rdfex/rdf",
               "Docs" => "http://rdfex.github.io/rdf)/"},
      files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"]
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:dialyxir, "~> 0.4", only: [:dev, :test]},
      {:credo, "~> 0.6", only: [:dev, :test]},
      {:ex_doc, "~> 0.14", only: :dev},
      {:mix_test_watch, "~> 0.3", only: :dev},
    ]
  end
end
