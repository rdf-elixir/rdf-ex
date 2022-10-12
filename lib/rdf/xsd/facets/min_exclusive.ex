defmodule RDF.XSD.Facets.MinExclusive do
  @moduledoc """
  `RDF.XSD.Facet` for `minExclusive`.

  `minExclusive` is the exclusive lower bound of the value space for a datatype
  with the ordered property.
  The value of `minExclusive` must be equal to some value in the value space of
  the base type or be equal to `{value}` in `{base type definition}`.

  see <https://www.w3.org/TR/xmlschema11-2/datatypes.html#rf-minExclusive>
  """

  use RDF.XSD.Facet, name: :min_exclusive, type: integer
end
