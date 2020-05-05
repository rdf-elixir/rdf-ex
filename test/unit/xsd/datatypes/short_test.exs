defmodule RDF.XSD.ShortTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.Short,
    name: "short",
    base: RDF.XSD.Int,
    base_primitive: RDF.XSD.Integer,
    comparable_datatypes: [RDF.XSD.Decimal, RDF.XSD.Double],
    applicable_facets: [RDF.XSD.Facets.MinInclusive, RDF.XSD.Facets.MaxInclusive],
    facets: %{
      min_inclusive: -32768,
      max_inclusive: 32767
    },
    valid: RDF.XSD.TestData.valid_shorts(),
    invalid: RDF.XSD.TestData.invalid_shorts()
end
