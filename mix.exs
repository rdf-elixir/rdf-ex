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
      {:inch_ex,                  only: :docs},
    ]
  end
end
