defmodule RDF.XSD.Facets.Length do
  @moduledoc """
  `RDF.XSD.Facet` for `length`.

  `length` is the number of units of length, where units of length varies
  depending on the type that is being derived from.
  The value of `length` must be a `nonNegativeInteger`.

  see <https://www.w3.org/TR/xmlschema11-2/datatypes.html#rf-length>
  """

  use RDF.XSD.Facet, name: :length, type: non_neg_integer
end
