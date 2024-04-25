defmodule RDF.TriG do
  @moduledoc """
  `RDF.TriG` provides support for the TriG serialization format.

  See `RDF.TriG.Decoder` and `RDF.TriG.Encoder` for the available options
  on the read and write functions.

  For more on TriG see <https://www.w3.org/TR/rdf12-trig/>.
  """

  use RDF.Serialization.Format

  import RDF.Sigils

  @id ~I<http://www.w3.org/ns/formats/TriG>
  @name :trig
  @extension "trig"
  @media_type "application/trig"
end
