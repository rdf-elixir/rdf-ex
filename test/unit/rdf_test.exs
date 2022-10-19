defmodule RDFTest do
  use ExUnit.Case

  use RDF.Vocabulary.Namespace
  defvocab EX, base_iri: "http://example.com/", terms: [], strict: false

  doctest RDF

  test "Datatype constructor alias functions" do
    assert RDF.langString("foo", language: "en") == RDF.Literal.new("foo", language: "en")
  end

  describe "default_prefixes/0" do
    test "when nothing configured returns the standard prefixes" do
      assert RDF.default_prefixes() == RDF.standard_prefixes()
    end
  end

  describe "__using__" do
    test "imports RDF.Sigils" do
      use RDF

      assert is_rdf_literal(~L"foo")
    end

    test "imports RDF.Guards" do
      use RDF

      assert is_rdf_literal(RDF.literal(42))
    end

    test "import RDF.Namespace.IRI" do
      use RDF
      assert term_to_iri(EX.Foo) == RDF.iri("http://example.com/Foo")
      assert term_to_iri(EX.bar()) == RDF.iri("http://example.com/bar")
    end

    test "add various aliases" do
      use RDF

      assert XSD.integer(42) == RDF.XSD.integer(42)
      assert NTriples.name() == :ntriples
      assert NQuads.name() == :nquads
      assert Turtle.name() == :turtle
    end
  end
end
