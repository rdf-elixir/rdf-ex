defmodule RDF.XSD.ByteTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.Byte,
    name: "byte",
    base: RDF.XSD.Short,
    base_primitive: RDF.XSD.Integer,
    comparable_datatypes: [RDF.XSD.Decimal, RDF.XSD.Double],
    applicable_facets: [
      RDF.XSD.Facets.MinInclusive,
      RDF.XSD.Facets.MaxInclusive,
      RDF.XSD.Facets.MinExclusive,
      RDF.XSD.Facets.MaxExclusive,
    ],
    facets: %{
      min_inclusive: -128,
      max_inclusive: 127,
      min_exclusive: nil,
      max_exclusive: nil

    },
    valid: RDF.XSD.TestData.valid_bytes(),
    invalid: RDF.XSD.TestData.invalid_bytes()
end
