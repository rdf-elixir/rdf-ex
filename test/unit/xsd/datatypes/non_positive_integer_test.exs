defmodule RDF.XSD.NonPositiveIntegerTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.NonPositiveInteger,
    name: "nonPositiveInteger",
    base: RDF.XSD.Integer,
    base_primitive: RDF.XSD.Integer,
    comparable_datatypes: [RDF.XSD.Decimal, RDF.XSD.Double],
    applicable_facets: [RDF.XSD.Facets.MinInclusive, RDF.XSD.Facets.MaxInclusive],
    facets: %{
      min_inclusive: nil,
      max_inclusive: 0
    },
    valid: RDF.XSD.TestData.valid_non_positive_integers(),
    invalid: RDF.XSD.TestData.invalid_non_positive_integers()
end
