defmodule RDF.XSD.Facets.MaxExclusive do
  @moduledoc """
  `RDF.XSD.Facet` for `maxExclusive`.

  `maxExclusive` is the exclusive upper bound of the value space for a datatype
  with the ordered property.
  The value of `maxExclusive` must be equal to some value in the value space
  of the base type or be equal to `{value}` in `{base type definition}`.

  see <https://www.w3.org/TR/xmlschema11-2/datatypes.html#rf-maxExclusive>
  """

  use RDF.XSD.Facet, name: :max_exclusive, type: integer
end
