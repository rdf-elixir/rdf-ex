defmodule RDF.Resource do
  alias RDF.{IRI, BlankNode}
  alias RDF.Resource.Generator

  @type t :: IRI.t() | BlankNode.t()

  def generator do
    Application.get_env(:rdf, :resource, generator: BlankNode)
    |> Generator.config()
  end

  def new(), do: generator() |> Generator.generate(nil)
  def new(args), do: generator() |> Generator.generate(args)
end
