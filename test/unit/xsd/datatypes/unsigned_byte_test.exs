defmodule RDF.XSD.UnsignedByteTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.UnsignedByte,
    name: "unsignedByte",
    base: RDF.XSD.UnsignedShort,
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
      min_inclusive: 0,
      max_inclusive: 255,
      min_exclusive: nil,
      max_exclusive: nil,
      total_digits: nil,
      pattern: nil
    },
    valid: RDF.XSD.TestData.valid_unsigned_bytes(),
    invalid: RDF.XSD.TestData.invalid_unsigned_bytes()
end
