defmodule RDF.Literal.Datatype.RegistryTest do
  use RDF.Test.Case

  alias RDF.TestDatatypes.Age
  alias RDF.Literal.Datatype
  alias RDF.NS
  alias RDF.TestDatatypes

  @unsupported_xsd_datatypes ~w[
                               ENTITIES
                               IDREF
                               language
                               Name
                               normalizedString
                               dayTimeDuration
                               QName
                               gYear
                               NMTOKENS
                               gDay
                               NOTATION
                               ID
                               duration
                               hexBinary
                               ENTITY
                               yearMonthDuration
                               IDREFS
                               token
                               NCName
                               NMTOKEN
                               gYearMonth
                               gMonth
                               gMonthDay
                             ]
                             |> Enum.map(fn xsd_datatype_name ->
                               RDF.iri(NS.XSD.__base_iri__() <> xsd_datatype_name)
                             end)

  @supported_xsd_datatypes RDF.NS.XSD.__iris__() -- @unsupported_xsd_datatypes

  describe "datatype/1" do
    test "builtin datatypes" do
      Enum.each(Datatype.Registry.builtin_datatypes(), fn datatype ->
        assert datatype == Datatype.Registry.datatype(datatype.id())
        assert datatype == Datatype.Registry.datatype(to_string(datatype.id()))
      end)
    end

    test "supported datatypes from the XSD namespace" do
      Enum.each(@supported_xsd_datatypes, fn xsd_datatype_iri ->
        assert xsd_datatype = Datatype.Registry.datatype(xsd_datatype_iri)
        assert xsd_datatype.id() == xsd_datatype_iri
      end)
    end

    test "unsupported datatypes from the XSD namespace" do
      Enum.each(@unsupported_xsd_datatypes, fn xsd_datatype_iri ->
        refute Datatype.Registry.datatype(xsd_datatype_iri)
        refute Datatype.Registry.datatype(to_string(xsd_datatype_iri))
      end)
    end

    test "with IRI of custom datatype" do
      assert Age == Datatype.Registry.datatype(Age.id())
    end

    test "with namespace terms" do
      assert Age == Datatype.Registry.datatype(EX.Age)
    end

    test "with a RDF.Literal" do
      assert XSD.String == Datatype.Registry.datatype(XSD.string("foo"))
      assert XSD.Integer == Datatype.Registry.datatype(XSD.integer(42))
      assert XSD.Byte == Datatype.Registry.datatype(XSD.byte(42))
      assert RDF.LangString == Datatype.Registry.datatype(~L"foo"en)

      assert RDF.Literal.Generic ==
               Datatype.Registry.datatype(RDF.literal("foo", datatype: "http://example.com"))
    end
  end

  test "datatype?/1" do
    assert Datatype.Registry.datatype?(XSD.string("foo"))
    assert Datatype.Registry.datatype?(~L"foo"en)
    assert Datatype.Registry.datatype?(XSD.integer(42))
    assert Datatype.Registry.datatype?(XSD.byte(42))
    assert Datatype.Registry.datatype?(TestDatatypes.Age.new(42))
    assert Datatype.Registry.datatype?(RDF.literal("foo", datatype: "http://example.com"))
    refute Datatype.Registry.datatype?(~r/foo/)
    refute Datatype.Registry.datatype?(:foo)
    refute Datatype.Registry.datatype?(42)
  end

  test "xsd_datatype?/1" do
    assert Datatype.Registry.xsd_datatype?(XSD.string("foo"))
    assert Datatype.Registry.xsd_datatype?(XSD.integer(42))
    assert Datatype.Registry.xsd_datatype?(XSD.byte(42))
    assert Datatype.Registry.xsd_datatype?(TestDatatypes.Age.new(42))
    refute Datatype.Registry.xsd_datatype?(~L"foo"en)
    refute Datatype.Registry.xsd_datatype?(RDF.literal("foo", datatype: "http://example.com"))
    refute Datatype.Registry.xsd_datatype?(~r/foo/)
    refute Datatype.Registry.xsd_datatype?(:foo)
    refute Datatype.Registry.xsd_datatype?(42)
  end

  test "numeric_datatype?/1" do
    assert Datatype.Registry.numeric_datatype?(XSD.integer(42))
    assert Datatype.Registry.numeric_datatype?(XSD.byte(42))
    assert Datatype.Registry.numeric_datatype?(TestDatatypes.Age.new(42))
    refute Datatype.Registry.numeric_datatype?(XSD.string("foo"))
    refute Datatype.Registry.numeric_datatype?(~L"foo"en)
    refute Datatype.Registry.numeric_datatype?(RDF.literal("foo", datatype: "http://example.com"))
    refute Datatype.Registry.numeric_datatype?(~r/foo/)
    refute Datatype.Registry.numeric_datatype?(:foo)
    refute Datatype.Registry.numeric_datatype?(42)
  end
end
