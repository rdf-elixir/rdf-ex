defmodule RDF.XSD.AnyURITest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.AnyURI,
    name: "anyURI",
    primitive: true,
    valid: %{
      # input => { value, lexical, canonicalized }
      "http://example.com/foo" =>
        {URI.parse("http://example.com/foo"), nil, "http://example.com/foo"},
      URI.parse("http://example.com/foo") =>
        {URI.parse("http://example.com/foo"), nil, "http://example.com/foo"}
    },
    invalid: [42, 3.14, true, false]


  describe "cast/1" do
    test "casting an anyURI returns the input as it is" do
      assert XSD.anyURI("http://example.com/") |> XSD.AnyURI.cast() ==
             XSD.anyURI("http://example.com/")
    end

    test "casting an RDF.IRI" do
      assert RDF.iri("http://example.com/") |> XSD.AnyURI.cast() ==
             XSD.anyURI("http://example.com/")
    end

    test "with coercible value" do
      assert URI.parse("http://example.com/") |> XSD.AnyURI.cast() ==
               XSD.anyURI("http://example.com/")
    end

    test "with non-coercible value" do
      assert XSD.string("http://example.com/") |> XSD.AnyURI.cast() == nil
      assert XSD.AnyURI.cast(make_ref()) == nil
    end
  end
end
