defmodule RDF.XSD.LongTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.Long,
    name: "long",
    base: RDF.XSD.Integer,
    base_primitive: RDF.XSD.Integer,
    comparable_datatypes: [RDF.XSD.Decimal, RDF.XSD.Double],
    applicable_facets: [RDF.XSD.Facets.MinInclusive, RDF.XSD.Facets.MaxInclusive],
    facets: %{
      min_inclusive: -9_223_372_036_854_775_808,
      max_inclusive: 9_223_372_036_854_775_807
    },
    valid: RDF.XSD.TestData.valid_longs(),
    invalid: RDF.XSD.TestData.invalid_longs()
end
