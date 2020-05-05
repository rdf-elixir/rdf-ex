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
end
