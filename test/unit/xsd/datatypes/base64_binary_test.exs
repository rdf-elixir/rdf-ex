defmodule RDF.XSD.Base64BinaryTest do
  use RDF.XSD.Datatype.Test.Case,
    datatype: RDF.XSD.Base64Binary,
    name: "base64Binary",
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
      # "foo" does not require any padding
      Base.encode64("foo") => {"foo", nil, Base.encode64("foo")},
      # "foob" does require padding
      Base.encode64("foob") => {"foob", nil, Base.encode64("foob")},
      Base.encode64(<<0::32>>) => {<<0::32>>, nil, Base.encode64(<<0::32>>)}
    },
    invalid: [
      "not a base64 encoded value",
      Base.encode64("foob", padding: false),
      0,
      42,
      3.14,
      true,
      false
    ]

  describe "new/2" do
    test "interpret string as value" do
      assert XSD.base64Binary("foo", as_value: true) == XSD.base64Binary(Base.encode64("foo"))
    end

    test "interpret string as value even if string is correctly encodded Base64" do
      assert XSD.base64Binary(Base.encode64("foo"), as_value: true) ==
               XSD.base64Binary(Base.encode64(Base.encode64("foo")))
    end
  end

  describe "cast/1" do
    test "casting a base64Binary returns the input as is" do
      assert XSD.base64Binary("foo", as_value: true) |> XSD.Base64Binary.cast() ==
               XSD.base64Binary("foo", as_value: true)
    end

    test "casting a string" do
      assert XSD.string("foo") |> XSD.Base64Binary.cast() ==
               XSD.base64Binary("foo", as_value: true)
    end

    test "string value is interpret as value (even if valid Base64 encoded string)" do
      assert XSD.string(Base.encode64("Hello World!"))
             |> XSD.Base64Binary.cast() !==
               XSD.base64Binary("Hello World!", as_value: true)
    end
  end
end
