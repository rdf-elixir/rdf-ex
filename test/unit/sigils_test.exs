defmodule RDF.SigilsTest do
  use ExUnit.Case, async: true

  import RDF.Sigils

  doctest RDF.Sigils

  describe "IRI sigil without interpolation" do
    test "creating an URI" do
      assert ~I<http://example.com> == RDF.uri("http://example.com")
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
