defmodule RDF.Literal.Datatype.RegistryTest do
  use ExUnit.Case

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


  describe "get/1" do
    test "IRIs of supported datatypes from the XSD namespace" do
      Enum.each(@supported_xsd_datatypes, fn xsd_datatype_iri ->
        assert xsd_datatype = Datatype.Registry.get(xsd_datatype_iri)
        assert xsd_datatype == Datatype.Registry.get(to_string(xsd_datatype_iri))
        assert RDF.iri(xsd_datatype.id) == xsd_datatype_iri

      end)
    end

    test "IRIs of unsupported datatypes from the XSD namespace" do
      Enum.each(@unsupported_xsd_datatypes, fn xsd_datatype_iri ->
        refute Datatype.Registry.get(xsd_datatype_iri)
        refute Datatype.Registry.get(to_string(xsd_datatype_iri))
      end)
    end
  end
end
