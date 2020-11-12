defmodule RDF.NQuads do
  @moduledoc """
  `RDF.NQuads` provides support for the N-Quads serialization format.

  N-Quads is a line-based plain-text format for encoding an RDF dataset, i.e. a
  collection of RDF graphs.

  An example of an RDF statement in N-Quads format:

      <https://hex.pm/> <http://purl.org/dc/terms/title> "Hex" <http://example.org/graphs/example> .

  see <https://www.w3.org/TR/n-quads/>
  """

  use RDF.Serialization.Format

  import RDF.Sigils

  @id ~I<http://www.w3.org/ns/formats/N-Quads>
  @name :nquads
  @extension "nq"
  @media_type "application/n-quads"
end
