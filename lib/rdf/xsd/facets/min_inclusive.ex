defmodule RDF.XSD.Facets.MinInclusive do
  @moduledoc """
  `RDF.XSD.Facet` for `minInclusive`.

  `minInclusive` is the inclusive lower bound of the value space for a datatype
  with the ordered property.
  The value of `minInclusive` must be equal to some value in the value space of
  the base type.

  see <https://www.w3.org/TR/xmlschema11-2/datatypes.html#rf-minInclusive>
  """

  use RDF.XSD.Facet, name: :min_inclusive, type: integer
end
