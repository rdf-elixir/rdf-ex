defmodule RDF.XSD.FloatTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.Float,
    name: "float",
    base: RDF.XSD.Double,
    base_primitive: RDF.XSD.Double,
    comparable_datatypes: [RDF.XSD.Integer, RDF.XSD.Decimal],
    applicable_facets: [
      RDF.XSD.Facets.MinInclusive,
      RDF.XSD.Facets.MaxInclusive,
      RDF.XSD.Facets.MinExclusive,
      RDF.XSD.Facets.MaxExclusive,
      RDF.XSD.Facets.Pattern
    ],
    facets: %{
      min_inclusive: nil,
      max_inclusive: nil,
      min_exclusive: nil,
      max_exclusive: nil,
      pattern: nil
    },
    valid: RDF.XSD.TestData.valid_floats(),
    invalid: RDF.XSD.TestData.invalid_floats()
end
