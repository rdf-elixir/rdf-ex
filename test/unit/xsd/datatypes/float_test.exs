defmodule RDF.XSD.FloatTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.Float,
    name: "float",
    base: RDF.XSD.Double,
    base_primitive: RDF.XSD.Double,
    comparable_datatypes: [RDF.XSD.Integer, RDF.XSD.Decimal],
    applicable_facets: [],
    facets: %{},
    valid: RDF.XSD.TestData.valid_floats(),
    invalid: RDF.XSD.TestData.invalid_floats()
end
