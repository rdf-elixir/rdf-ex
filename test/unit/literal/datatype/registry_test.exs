defmodule RDF.Literal.Datatype.RegistryTest do
  use RDF.Test.Case

  alias RDF.TestDatatypes.Age
  alias RDF.Literal.Datatype
  alias RDF.NS

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
      base64Binary
      token
      NCName
      NMTOKEN
      gYearMonth
      gMonth
      gMonthDay
    ]
    |> Enum.map(fn xsd_datatype_name -> RDF.iri(NS.XSD.__base_iri__ <> xsd_datatype_name) end)

  @supported_xsd_datatypes RDF.NS.XSD.__iris__() -- @unsupported_xsd_datatypes


  describe "datatype/1" do
    test "core datatypes" do
      Enum.each(Datatype.Registry.core_datatypes(), fn datatype ->
        assert datatype == Datatype.Registry.datatype(datatype.id)
        assert datatype == Datatype.Registry.datatype(to_string(datatype.id))
      end)
    end

    test "supported datatypes from the XSD namespace" do
      Enum.each(@supported_xsd_datatypes, fn xsd_datatype_iri ->
        assert xsd_datatype = Datatype.Registry.datatype(xsd_datatype_iri)
        assert xsd_datatype.id == xsd_datatype_iri
      end)
    end

    test "unsupported datatypes from the XSD namespace" do
      Enum.each(@unsupported_xsd_datatypes, fn xsd_datatype_iri ->
        refute Datatype.Registry.datatype(xsd_datatype_iri)
        refute Datatype.Registry.datatype(to_string(xsd_datatype_iri))
      end)
    end

    test "with IRI of custom datatype" do
      assert Age == Datatype.Registry.datatype(Age.id)
    end

    test "with namespace terms" do
      assert Age == Datatype.Registry.datatype(EX.Age)
    end
  end

  describe "xsd_datatype/1" do
    test "when a core XSD datatype with the given IRI exists" do
      assert XSD.String = Datatype.Registry.xsd_datatype(NS.XSD.string)
    end

    test "when a custom XSD datatype with the given IRI exists" do
      assert Age = Datatype.Registry.xsd_datatype(EX.Age)
    end

    test "when  datatype with the given IRI exists, but it is not an XSD datatype" do
      refute Datatype.Registry.xsd_datatype(RDF.langString)
    end

    test "when no datatype with the given IRI exists" do
      refute Datatype.Registry.xsd_datatype(EX.foo)
    end
  end
end
