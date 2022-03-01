defmodule RDF.Resource do
  alias RDF.{IRI, BlankNode}
  alias RDF.Resource.Generator

  @type t :: IRI.t() | BlankNode.t()

  @default_generator (Application.get_env(:rdf, :resource) || [generator: BlankNode])
                     |> Generator.config()

  def new(), do: Generator.generate(@default_generator, nil)
  def new(args), do: Generator.generate(@default_generator, args)
end
