defmodule RDF.XSD.Facets.MaxLength do
  @moduledoc """
  `RDF.XSD.Facet` for `maxLength`.

  `maxLength` is the maximum number of units of length, where units of length
  varies depending on the type that is being derived from.
  The value of `maxLength` must be a `nonNegativeInteger`.

  see <https://www.w3.org/TR/xmlschema11-2/datatypes.html#rf-maxLength>
  """

  use RDF.XSD.Facet, name: :max_length, type: non_neg_integer
end
