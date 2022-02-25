defmodule RDF.Resource do
  alias RDF.{IRI, BlankNode}

  @type t :: IRI.t() | BlankNode.t()
end
