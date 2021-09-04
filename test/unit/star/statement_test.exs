defmodule RDF.Star.StatementTest do
  use RDF.Test.Case

  doctest RDF.Star.Statement

  alias RDF.Star.{Statement, Triple, Quad}

  describe "valid?/1" do
    @iri ~I<http://example.com/Foo>
    @bnode ~B<foo>
    @valid_literal ~L"foo"

    test "valid triples" do
      Enum.each(valid_triples(), fn argument ->
        assert Statement.valid?(argument) == true
        assert Triple.valid?(argument) == true
        refute Quad.valid?(argument)
      end)
    end

    test "valid RDF-star triples" do
      Enum.each(valid_star_triples(), fn argument ->
        assert Statement.valid?(argument) == true
        assert Triple.valid?(argument) == true
        refute Quad.valid?(argument)
      end)
    end

    test "nested RDF-star triples" do
      Enum.flat_map(valid_star_triples(), fn star_triple ->
        [
          {star_triple, EX.p(), EX.o()},
          {EX.s(), EX.p(), star_triple}
        ]
      end)
      |> Enum.each(fn argument ->
        assert Statement.valid?(argument) == true
        assert Triple.valid?(argument) == true
        refute Quad.valid?(argument)
      end)
    end

    test "valid RDF quads" do
      Enum.each(valid_quads(), fn argument ->
        assert Statement.valid?(argument) == true
        assert Quad.valid?(argument) == true
        refute Triple.valid?(argument)
      end)
    end

    test "valid RDF-star quads" do
      Enum.each(valid_star_quads(), fn argument ->
        assert Statement.valid?(argument) == true
        assert Quad.valid?(argument) == true
        refute Triple.valid?(argument)
      end)
    end

    test "nested RDF-star quads" do
      Enum.flat_map(valid_star_triples(), fn star_triple ->
        [
          {star_triple, EX.p(), EX.o(), EX.graph()},
          {EX.s(), EX.p(), star_triple, EX.graph()}
        ]
      end)
      |> Enum.each(fn argument ->
        assert Statement.valid?(argument) == true
        assert Quad.valid?(argument) == true
        refute Triple.valid?(argument)
      end)
    end

    test "with invalid RDF triples" do
      Enum.each(invalid_triples(), fn argument ->
        assert Statement.valid?(argument) == false
        assert Triple.valid?(argument) == false
        assert Quad.valid?(argument) == false
      end)
    end

    test "with invalid RDF-star triples" do
      [
        {{@iri, @iri}, @iri, @iri},
        {{@iri, @iri, @iri, @iri}, @iri, @iri},
        {{@iri, @valid_literal, @iri}, @iri, @iri},
        {@iri, @iri, {@iri, @iri}},
        {@iri, @iri, {@iri, @valid_literal, @iri}}
      ]
      |> Enum.each(fn argument ->
        assert Statement.valid?(argument) == false
        assert Triple.valid?(argument) == false
        assert Quad.valid?(argument) == false
      end)
    end

    test "with invalid RDF quads" do
      Enum.each(invalid_quads(), fn argument ->
        assert Statement.valid?(argument) == false
        assert Triple.valid?(argument) == false
        assert Quad.valid?(argument) == false
      end)
    end

    test "with invalid RDF-star quads" do
      [
        {{@iri, @iri}, @iri, @iri, @iri},
        {{@iri, @iri, @iri, @iri}, @iri, @iri, @iri},
        {{@iri, @valid_literal, @iri}, @iri, @iri, @iri},
        {@iri, @iri, {@iri, @iri}, @iri},
        {@iri, @iri, {@iri, @valid_literal, @iri}, @iri}
      ]
      |> Enum.each(fn argument ->
        assert Statement.valid?(argument) == false
        assert Triple.valid?(argument) == false
        assert Quad.valid?(argument) == false
      end)
    end

    test "with invalid statements by number of elements" do
      refute Statement.valid?({@iri, @iri})
      refute Triple.valid?({@iri, @iri})
      refute Quad.valid?({@iri, @iri})

      refute Statement.valid?({@iri, @iri, @iri, @iri, @iri})
      refute Triple.valid?({@iri, @iri, @iri, @iri, @iri})
      refute Quad.valid?({@iri, @iri, @iri, @iri, @iri})

      refute Triple.valid?({@iri, @iri, @iri, @iri})
      refute Quad.valid?({@iri, @iri, @iri})
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
        refute Statement.valid?(arg)
        refute Triple.valid?(arg)
        refute Quad.valid?(arg)
      end)
    end
  end
end
