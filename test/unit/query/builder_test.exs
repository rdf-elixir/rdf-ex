defmodule RDF.Query.BuilderTest do
  use RDF.Test.Case

  alias RDF.Query.{BGP, Builder}

  defp bgp(triple_patterns) when is_list(triple_patterns),
       do: {:ok, %BGP{triple_patterns: triple_patterns}}

  describe "new/1" do
    test "empty triple pattern" do
      assert Builder.bgp([]) == bgp([])
    end

    test "one triple pattern doesn't require list brackets" do
      assert Builder.bgp({EX.s, EX.p, EX.o}) ==
               bgp [{EX.s, EX.p, EX.o}]
    end

    test "variables" do
      assert Builder.bgp([{:s?, :p?, :o?}]) == bgp [{:s, :p, :o}]
    end

    test "blank nodes" do
      assert Builder.bgp([{RDF.bnode("s"), RDF.bnode("p"), RDF.bnode("o")}]) ==
               bgp [{RDF.bnode("s"), RDF.bnode("p"), RDF.bnode("o")}]
    end

    test "blank nodes as atoms" do
      assert Builder.bgp([{:_s, :_p, :_o}]) ==
               bgp [{RDF.bnode("s"), RDF.bnode("p"), RDF.bnode("o")}]
    end

    test "variable notation has precedence over blank node notation" do
      assert Builder.bgp([{:_s?, :_p?, :_o?}]) == bgp [{:_s, :_p, :_o}]
    end

    test "IRIs" do
      assert Builder.bgp([{
               RDF.iri("http://example.com/s"),
               RDF.iri("http://example.com/p"),
               RDF.iri("http://example.com/o")}]
             ) == bgp [{EX.s, EX.p, EX.o}]

      assert Builder.bgp([{
               ~I<http://example.com/s>,
               ~I<http://example.com/p>,
               ~I<http://example.com/o>}]
             ) == bgp [{EX.s, EX.p, EX.o}]

      assert Builder.bgp([{EX.s, EX.p, EX.o}]) ==
               bgp [{EX.s, EX.p, EX.o}]
    end

    test "vocabulary term atoms" do
      assert Builder.bgp([{EX.S, EX.P, EX.O}]) ==
               bgp [{RDF.iri(EX.S), RDF.iri(EX.P), RDF.iri(EX.O)}]
    end

    test "special :a atom for rdf:type" do
      assert Builder.bgp([{EX.S, :a, EX.O}]) ==
               bgp [{RDF.iri(EX.S), RDF.type, RDF.iri(EX.O)}]
    end

    test "URIs" do
      assert Builder.bgp([{
               URI.parse("http://example.com/s"),
               URI.parse("http://example.com/p"),
               URI.parse("http://example.com/o")}]
             ) == bgp [{EX.s, EX.p, EX.o}]
    end

    test "literals" do
      assert Builder.bgp([{EX.s, EX.p, ~L"foo"}]) ==
               bgp [{EX.s, EX.p, ~L"foo"}]
    end

    test "values coercible to literals" do
      assert Builder.bgp([{EX.s, EX.p, "foo"}]) ==
               bgp [{EX.s, EX.p, ~L"foo"}]
      assert Builder.bgp([{EX.s, EX.p, 42}]) ==
               bgp [{EX.s, EX.p, RDF.literal(42)}]
      assert Builder.bgp([{EX.s, EX.p, true}]) ==
               bgp [{EX.s, EX.p, XSD.true}]
    end

    test "literals on non-object positions" do
      assert {:error, %RDF.Query.InvalidError{}} =
               Builder.bgp([{~L"foo", EX.p, ~L"bar"}])
    end

    test "multiple triple patterns" do
      assert Builder.bgp([
               {EX.S, EX.p, :o?},
               {:o?, EX.p2, 42}
             ]) ==
               bgp [
                 {RDF.iri(EX.S), EX.p, :o},
                 {:o, EX.p2, RDF.literal(42)}
               ]
    end

    test "multiple objects to the same subject-predicate" do
      assert Builder.bgp([{EX.s, EX.p, EX.o1, EX.o2}]) ==
               bgp [
                 {EX.s, EX.p, EX.o1},
                 {EX.s, EX.p, EX.o2}
               ]

      assert Builder.bgp({EX.s, EX.p, EX.o1, EX.o2}) ==
               bgp [
                 {EX.s, EX.p, EX.o1},
                 {EX.s, EX.p, EX.o2}
               ]

      assert Builder.bgp({EX.s, EX.p, :o?, false, 42, "foo"}) ==
               bgp [
                 {EX.s, EX.p, :o},
                 {EX.s, EX.p, XSD.false},
                 {EX.s, EX.p, RDF.literal(42)},
                 {EX.s, EX.p, RDF.literal("foo")}
               ]
    end

    test "multiple predicate-object pairs to the same subject" do
      assert Builder.bgp([{
               EX.s,
               [EX.p1, EX.o1],
               [EX.p2, EX.o2],
             }]) ==
               bgp [
                 {EX.s, EX.p1, EX.o1},
                 {EX.s, EX.p2, EX.o2}
               ]

      assert Builder.bgp([{
               EX.s,
               [:a, :o?],
               [EX.p1, 42, 3.14],
               [EX.p2, "foo", true],
             }]) ==
               bgp [
                 {EX.s, RDF.type, :o},
                 {EX.s, EX.p1, RDF.literal(42)},
                 {EX.s, EX.p1, RDF.literal(3.14)},
                 {EX.s, EX.p2, RDF.literal("foo")},
                 {EX.s, EX.p2, XSD.true}
               ]

      assert Builder.bgp([{EX.s, [EX.p, EX.o]}]) ==
               bgp [{EX.s, EX.p, EX.o}]
    end
  end
end
