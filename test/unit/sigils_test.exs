defmodule RDF.SigilsTest do
  use ExUnit.Case, async: true

  import RDF.Sigils

  doctest RDF.Sigils

  describe "~I sigil" do
    test "creates an IRI" do
      assert ~I<http://example.com> == RDF.iri("http://example.com")
    end

    test "escaping" do
      assert ~I<http://example.com/f\no> == RDF.iri("http://example.com/f\\no")
    end

    test "in pattern matches" do
      assert (case RDF.iri("http://example.com/foo") do
                ~I<http://example.com/foo> -> "match"
                _ -> :mismatch
              end) == "match"
    end
  end

  describe "~i sigil" do
    test "without interpolation" do
      assert ~i<http://example.com> == RDF.iri("http://example.com")
    end

    test "with interpolation" do
      assert ~i<http://example.com/#{1 + 2}> == RDF.iri("http://example.com/3")
      assert ~i<http://example.com/#{:foo}> == RDF.iri("http://example.com/foo")
      assert ~i<http://example.com/#{"foo"}> == RDF.iri("http://example.com/foo")
    end

    test "escaping" do
      assert ~i<http://example.com/f\no> == RDF.iri("http://example.com/f\\no")
    end
  end

  describe "~B sigil" do
    test "creates a blank node" do
      assert ~B<foo> == RDF.bnode("foo")
      assert ~B<foo> == RDF.bnode("foo")
    end
  end

  describe "~b sigil" do
    test "without interpolation" do
      assert ~b<foo> == RDF.bnode("foo")
    end

    test "with interpolation" do
      assert ~b<foo#{1 + 2}> == RDF.bnode("foo3")
    end
  end

  describe "~L sigil" do
    test "creates a plain Literal" do
      assert ~L"foo" == RDF.literal("foo")
    end

    test "creates a language-tagged Literal" do
      assert ~L"foo"en == RDF.literal("foo", language: "en")
    end
  end

  describe "~l sigil" do
    test "without interpolation" do
      assert ~l"foo" == RDF.literal("foo")
      assert ~l"foo"en == RDF.literal("foo", language: "en")
    end

    test "with interpolation" do
      assert ~l"foo#{1 + 2}" == RDF.literal("foo3")
      assert ~l"foo#{1 + 2}"en == RDF.literal("foo3", language: "en")
    end
  end
end
