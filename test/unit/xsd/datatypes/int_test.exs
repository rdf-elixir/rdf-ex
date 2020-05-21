defmodule RDF.XSD.IntTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.Int,
    name: "int",
    base: RDF.XSD.Long,
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
      min_inclusive: -2_147_483_648,
      max_inclusive: 2_147_483_647,
      min_exclusive: nil,
      max_exclusive: nil,
      total_digits: nil,
      pattern: nil
    },
    valid: RDF.XSD.TestData.valid_ints(),
    invalid: RDF.XSD.TestData.invalid_ints()
end
