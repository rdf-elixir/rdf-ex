defmodule RDF.Core.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :rdf_core,
      version: @version,
      description: "An implementation of RDF and accompanied standards for Elixir",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      package: package,
      deps: deps
    ]
  end

  defp package do
    [
      name: :rdf_core,
      maintainers: ["Marcel Otto"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/rdfex/rdf_core",
               "Docs" => "http://rdfex.github.io/rdf_core)/"},
      files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"]
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end
end
