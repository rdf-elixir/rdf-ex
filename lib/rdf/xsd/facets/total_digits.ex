defmodule RDF.XSD.Facets.TotalDigits do
  @moduledoc """
  `RDF.XSD.Facet` for `totalDigits`.

  `totalDigits` restricts the magnitude and arithmetic precision of values in
  the value spaces of decimal and datatypes derived from it.

  see <https://www.w3.org/TR/xmlschema11-2/datatypes.html#rf-totalDigits>
  """

  use RDF.XSD.Facet, name: :total_digits, type: pos_integer
end
