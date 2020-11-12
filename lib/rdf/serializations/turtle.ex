defmodule RDF.Turtle do
  @moduledoc """
  `RDF.Turtle` provides support for the Turtle serialization format.

  See `RDF.Turtle.Decoder` and `RDF.Turtle.Encoder` for the available options
  on the read and write functions.

  For more on Turtle see <https://www.w3.org/TR/turtle/>.
  """

  use RDF.Serialization.Format

  import RDF.Sigils

  @id ~I<http://www.w3.org/ns/formats/Turtle>
  @name :turtle
  @extension "ttl"
  @media_type "text/turtle"
end
