defmodule RDF.XSD.ByteTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.Byte,
    name: "byte",
    base: RDF.XSD.Short,
    base_primitive: RDF.XSD.Integer,
    comparable_datatypes: [RDF.XSD.Decimal, RDF.XSD.Double],
    applicable_facets: [RDF.XSD.Facets.MinInclusive, RDF.XSD.Facets.MaxInclusive],
    facets: %{
      min_inclusive: -128,
      max_inclusive: 127
    },
    valid: RDF.XSD.TestData.valid_bytes(),
    invalid: RDF.XSD.TestData.invalid_bytes()
end
