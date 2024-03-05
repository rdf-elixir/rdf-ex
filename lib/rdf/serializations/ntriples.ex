defmodule RDF.NTriples do
  @moduledoc """
  `RDF.NTriples` provides support for the N-Triples serialization format.

  N-Triples is a line-based plain-text format for encoding an RDF graph.
  It is a very restricted, explicit and well-defined subset of both
  [Turtle](http://www.w3.org/TeamSubmission/turtle/) and
  [Notation3](http://www.w3.org/TeamSubmission/n3/) (N3).

  An example of an RDF statement in N-Triples format:

  ```ntriples
  <https://hex.pm/> <http://purl.org/dc/terms/title> "Hex" .
  ```

  see <https://www.w3.org/TR/n-triples/>
  """

  use RDF.Serialization.Format

  import RDF.Sigils

  @id ~I<http://www.w3.org/ns/formats/N-Triples>
  @name :ntriples
  @extension "nt"
  @media_type "application/n-triples"
end
