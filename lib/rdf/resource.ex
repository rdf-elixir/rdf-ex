defmodule RDF.Resource do
  alias RDF.{IRI, BlankNode}
  alias RDF.Resource.Generator

  @type t :: IRI.t() | BlankNode.t()

  def generator_config do
    Application.get_env(:rdf, :resource, generator: BlankNode)
  end

  def new(), do: generator_config() |> Generator.generate()
  def new(value), do: generator_config() |> Generator.generate(value)
end
