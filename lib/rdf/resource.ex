defmodule RDF.Resource do
  @moduledoc """
  Shared functions over `RDF.IRI`s and `RDF.BlankNode`s.
  """

  alias RDF.{IRI, BlankNode}

  @type t :: IRI.t() | BlankNode.t()
end
