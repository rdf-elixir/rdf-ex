defmodule RDF.SigilsTest do
  use ExUnit.Case, async: true

  import RDF.Sigils

  doctest RDF.Sigils

  describe "IRI sigil without interpolation" do
    test "creating an IRI" do
      assert ~I<http://example.com> == RDF.iri("http://example.com")
    end
  end

  describe "Blank node sigil without interpolation" do
    test "creating a blank node" do
      assert ~B<foo> == RDF.bnode("foo")
    end
  end

  describe "Literal sigil without interpolation" do
    test "creating a plain Literal" do
      assert ~L"foo" == RDF.literal("foo")
    end

    test "creating a language-tagged Literal" do
      assert ~L"foo"en == RDF.literal("foo", language: "en")
    end
  end
end
