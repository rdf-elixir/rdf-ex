defmodule RDF.XSD.NonPositiveIntegerTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.NonPositiveInteger,
    name: "nonPositiveInteger",
    base: RDF.XSD.Integer,
    base_primitive: RDF.XSD.Integer,
    comparable_datatypes: [RDF.XSD.Decimal, RDF.XSD.Double],
    applicable_facets: [
      RDF.XSD.Facets.MinInclusive,
      RDF.XSD.Facets.MaxInclusive,
      RDF.XSD.Facets.MinExclusive,
      RDF.XSD.Facets.MaxExclusive,
      RDF.XSD.Facets.TotalDigits,
      RDF.XSD.Facets.Pattern
    ],
    facets: %{
      min_inclusive: nil,
      max_inclusive: 0,
      min_exclusive: nil,
      max_exclusive: nil,
      total_digits: nil,
      pattern: nil
    },
    valid: RDF.XSD.TestData.valid_non_positive_integers(),
    invalid: RDF.XSD.TestData.invalid_non_positive_integers()
end
