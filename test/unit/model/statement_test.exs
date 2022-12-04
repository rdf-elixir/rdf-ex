defmodule RDF.StatementTest do
  use RDF.Test.Case

  doctest RDF.Statement

  describe "valid?/1" do
    @iri ~I<http://example.com/Foo>
    @bnode ~B<foo>
    @valid_literal ~L"foo"

    test "valid triples" do
      Enum.each(valid_triples(), fn argument ->
        assert RDF.Statement.valid?(argument) == true
        assert RDF.Triple.valid?(argument) == true
        refute RDF.Quad.valid?(argument)
      end)
    end

    test "valid quads" do
      Enum.each(valid_quads(), fn argument ->
        assert RDF.Statement.valid?(argument) == true
        assert RDF.Quad.valid?(argument) == true
        refute RDF.Triple.valid?(argument)
      end)
    end

    test "with invalid triples" do
      Enum.each(invalid_triples(), fn argument ->
        assert RDF.Statement.valid?(argument) == false
        assert RDF.Triple.valid?(argument) == false
        assert RDF.Quad.valid?(argument) == false
      end)
    end

    test "with invalid quads" do
      Enum.each(invalid_quads(), fn argument ->
        assert RDF.Statement.valid?(argument) == false
        assert RDF.Triple.valid?(argument) == false
        assert RDF.Quad.valid?(argument) == false
      end)
    end

    test "with invalid statements by number of elements" do
      refute RDF.Statement.valid?({@iri, @iri})
      refute RDF.Triple.valid?({@iri, @iri})
      refute RDF.Quad.valid?({@iri, @iri})

      refute RDF.Statement.valid?({@iri, @iri, @iri, @iri, @iri})
      refute RDF.Triple.valid?({@iri, @iri, @iri, @iri, @iri})
      refute RDF.Quad.valid?({@iri, @iri, @iri, @iri, @iri})

      refute RDF.Triple.valid?({@iri, @iri, @iri, @iri})
      refute RDF.Quad.valid?({@iri, @iri, @iri})
    end

    test "with non-tuples" do
      [
        42,
        "foo",
        @iri,
        @bnode,
        @valid_literal
      ]
      |> Enum.each(fn arg ->
        refute RDF.Statement.valid?(arg)
        refute RDF.Triple.valid?(arg)
        refute RDF.Quad.valid?(arg)
      end)
    end
  end

  test "bnodes/1" do
    assert RDF.Statement.bnodes({@iri, @iri, @iri}) == []
    assert RDF.Statement.bnodes({@iri, @iri, @iri, @iri}) == []
    assert RDF.Statement.bnodes({@bnode, @iri, @bnode}) == [@bnode]
    assert RDF.Statement.bnodes({@bnode, @iri, @bnode, @bnode}) == [@bnode]
    assert RDF.Statement.bnodes({~B<b1>, @iri, ~B<b2>}) == [~B<b1>, ~B<b2>]
    assert RDF.Statement.bnodes({~B<b1>, @iri, ~B<b2>, ~B<b3>}) == [~B<b1>, ~B<b2>, ~B<b3>]
  end
end
