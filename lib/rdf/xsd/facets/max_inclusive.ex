defmodule RDF.XSD.Facets.MaxInclusive do
  @moduledoc """
  `RDF.XSD.Facet` for `maxInclusive`.

  `maxInclusive` is the inclusive upper bound of the value space for a datatype
  with the ordered property.
  The value of `maxInclusive` must be equal to some value in the value space of
  the base type.

  see <https://www.w3.org/TR/xmlschema11-2/datatypes.html#rf-maxInclusive>
  """

  use RDF.XSD.Facet, name: :max_inclusive, type: integer
end
