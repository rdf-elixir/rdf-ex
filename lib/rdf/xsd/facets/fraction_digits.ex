defmodule RDF.XSD.Facets.FractionDigits do
  @moduledoc """
  `RDF.XSD.Facet` for `fractionDigits`.

  `fractionDigits` places an upper limit on the arithmetic precision of decimal
  values: if the `{value}` of `fractionDigits = f`, then the value space is
  restricted to values equal to `i / 10n` for some integers `i` and `n` and
  `0 ≤ n ≤ f`. The value of `fractionDigits` must be a nonNegativeInteger.

  see <https://www.w3.org/TR/xmlschema11-2/datatypes.html#rf-fractionDigits>
  """

  use RDF.XSD.Facet, name: :fraction_digits, type: non_neg_integer
end
