defmodule RDF.XSD.ShortTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.Short,
    name: "short",
    base: RDF.XSD.Int,
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
      min_inclusive: -32_768,
      max_inclusive: 32_767,
      min_exclusive: nil,
      max_exclusive: nil,
      total_digits: nil,
      pattern: nil
    },
    valid: RDF.XSD.TestData.valid_shorts(),
    invalid: RDF.XSD.TestData.invalid_shorts()
end
