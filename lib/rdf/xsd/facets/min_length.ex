defmodule RDF.XSD.Facets.MinLength do
  @moduledoc """
  `RDF.XSD.Facet` for `minLength`.

  `minLength` is the minimum number of units of length, where units of length
  varies depending on the type that is being derived from.
  The value of `minLength`  must be a `nonNegativeInteger`.

  see <https://www.w3.org/TR/xmlschema11-2/datatypes.html#rf-minLength>
  """

  use RDF.XSD.Facet, name: :min_length, type: non_neg_integer
end
