defmodule RDF.XSD.AnyURITest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.AnyURI,
    name: "anyURI",
    primitive: true,
    applicable_facets: [
      RDF.XSD.Facets.MinLength,
      RDF.XSD.Facets.MaxLength,
      RDF.XSD.Facets.Length,
      RDF.XSD.Facets.Pattern
    ],
    facets: %{
      max_length: nil,
      min_length: nil,
      length: nil,
      pattern: nil
    },
    valid: %{
      # input => { value, lexical, canonicalized }
      "http://example.com/foo" =>
        {URI.parse("http://example.com/foo"), nil, "http://example.com/foo"},
      URI.parse("http://example.com/foo") =>
        {URI.parse("http://example.com/foo"), nil, "http://example.com/foo"},
      RDF.iri("http://example.com/foo") =>
        {URI.parse("http://example.com/foo"), nil, "http://example.com/foo"},
      RDF.List =>
        {URI.parse("http://www.w3.org/1999/02/22-rdf-syntax-ns#List"), nil, "http://www.w3.org/1999/02/22-rdf-syntax-ns#List"},
    },
    invalid: [42, 3.14, Foo, :foo, true, false]


  describe "cast/1" do
    test "casting an anyURI returns the input as it is" do
      assert XSD.anyURI("http://example.com/") |> XSD.AnyURI.cast() ==
             XSD.anyURI("http://example.com/")
    end

    test "casting an RDF.IRI" do
      assert RDF.iri("http://example.com/") |> XSD.AnyURI.cast() ==
               XSD.anyURI("http://example.com/")
    end
  end
end
