defmodule RDF.Turtle do
  @moduledoc """
  `RDF.Turtle` provides support for reading and writing the Turtle
  serialization format.

  see <https://www.w3.org/TR/turtle/>
  """

  use RDF.Serialization

  import RDF.Sigils

  @id           ~I<http://www.w3.org/ns/formats/Turtle>
  @name         :turtle
  @extension    "ttl"
  @content_type "text/turtle"

end
