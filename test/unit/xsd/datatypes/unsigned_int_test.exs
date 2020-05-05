defmodule RDF.XSD.UnsignedIntTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.UnsignedInt,
    name: "unsignedInt",
    base: RDF.XSD.UnsignedLong,
    base_primitive: RDF.XSD.Integer,
    comparable_datatypes: [RDF.XSD.Decimal, RDF.XSD.Double],
    applicable_facets: [RDF.XSD.Facets.MinInclusive, RDF.XSD.Facets.MaxInclusive],
    facets: %{
      min_inclusive: 0,
      max_inclusive: 4_294_967_295
    },
    valid: RDF.XSD.TestData.valid_unsigned_ints(),
    invalid: RDF.XSD.TestData.invalid_unsigned_ints()
end
