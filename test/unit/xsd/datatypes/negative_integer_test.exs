defmodule RDF.XSD.NegativeIntegerTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.NegativeInteger,
    name: "negativeInteger",
    base: RDF.XSD.NonPositiveInteger,
    base_primitive: RDF.XSD.Integer,
    comparable_datatypes: [RDF.XSD.Decimal, RDF.XSD.Double],
    applicable_facets: [
      RDF.XSD.Facets.MinInclusive,
      RDF.XSD.Facets.MaxInclusive,
      RDF.XSD.Facets.MinExclusive,
      RDF.XSD.Facets.MaxExclusive,
    ],
    facets: %{
      min_inclusive: nil,
      max_inclusive: -1,
      min_exclusive: nil,
      max_exclusive: nil
    },
    valid: RDF.XSD.TestData.valid_negative_integers(),
    invalid: RDF.XSD.TestData.invalid_negative_integers()
end
