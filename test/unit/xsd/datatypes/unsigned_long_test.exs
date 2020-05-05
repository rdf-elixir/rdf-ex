defmodule RDF.XSD.UnsignedLongTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.UnsignedLong,
    name: "unsignedLong",
    base: RDF.XSD.NonNegativeInteger,
    base_primitive: RDF.XSD.Integer,
    comparable_datatypes: [RDF.XSD.Decimal, RDF.XSD.Double],
    applicable_facets: [RDF.XSD.Facets.MinInclusive, RDF.XSD.Facets.MaxInclusive],
    facets: %{
      min_inclusive: 0,
      max_inclusive: 18_446_744_073_709_551_615
    },
    valid: RDF.XSD.TestData.valid_unsigned_longs(),
    invalid: RDF.XSD.TestData.invalid_unsigned_longs()
end
