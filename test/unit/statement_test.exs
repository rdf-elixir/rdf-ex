defmodule RDF.StatementTest do
  use RDF.Test.Case

  doctest RDF.Statement

  describe "valid?/1" do
    @iri ~I<http://example.com/Foo>
    @bnode ~B<foo>
    @valid_literal ~L"foo"
    @invalid_literal XSD.integer("foo")

    @valid_triples [
      {@iri, @iri, @iri},
      {@bnode, @iri, @iri},
      {@iri, @iri, @bnode},
      {@bnode, @iri, @bnode},
      {@iri, @iri, @valid_literal},
      {@bnode, @iri, @valid_literal},
      {@iri, @iri, @invalid_literal},
      {@bnode, @iri, @invalid_literal}
    ]

    @valid_quads [
      {@iri, @iri, @iri, @iri},
      {@bnode, @iri, @iri, @iri},
      {@iri, @iri, @bnode, @iri},
      {@bnode, @iri, @bnode, @iri},
      {@iri, @iri, @valid_literal, @iri},
      {@bnode, @iri, @valid_literal, @iri},
      {@iri, @iri, @invalid_literal, @iri},
      {@bnode, @iri, @invalid_literal, @iri}
    ]

    test "valid triples" do
      Enum.each(@valid_triples, fn argument ->
        assert RDF.Statement.valid?(argument) == true
        assert RDF.Triple.valid?(argument) == true
        refute RDF.Quad.valid?(argument)
      end)
    end

    test "valid quads" do
      Enum.each(@valid_quads, fn argument ->
        assert RDF.Statement.valid?(argument) == true
        assert RDF.Quad.valid?(argument) == true
        refute RDF.Triple.valid?(argument)
      end)
    end

    test "with invalid triples" do
      [
        {@iri, @bnode, @iri},
        {@valid_literal, @iri, @iri},
        {@iri, @valid_literal, @iri}
      ]
      |> Enum.each(fn argument ->
        assert RDF.Statement.valid?(argument) == false
        assert RDF.Triple.valid?(argument) == false
        assert RDF.Quad.valid?(argument) == false
      end)
    end

    test "with invalid quads" do
      [
        {@iri, @bnode, @iri, @iri},
        {@iri, @iri, @iri, @bnode},
        {@valid_literal, @iri, @iri, @iri},
        {@iri, @valid_literal, @iri, @iri},
        {@iri, @iri, @iri, @valid_literal}
      ]
      |> Enum.each(fn argument ->
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
        @bnode
      ]
      |> Enum.each(fn arg ->
        refute RDF.Statement.valid?(arg)
        refute RDF.Triple.valid?(arg)
        refute RDF.Quad.valid?(arg)
      end)
    end
  end
end
