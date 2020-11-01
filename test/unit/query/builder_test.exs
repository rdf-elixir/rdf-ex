defmodule RDF.Query.BuilderTest do
  use RDF.Query.Test.Case

  alias RDF.Query.Builder

  describe "bgp/1" do
    test "empty triple pattern" do
      assert Builder.bgp([]) == ok_bgp_struct([])
    end

    test "one triple pattern doesn't require list brackets" do
      assert Builder.bgp({EX.s(), EX.p(), EX.o()}) ==
               ok_bgp_struct([{EX.s(), EX.p(), EX.o()}])
    end

    test "variables" do
      assert Builder.bgp([{:s?, :p?, :o?}]) == ok_bgp_struct([{:s, :p, :o}])
    end

    test "blank nodes" do
      assert Builder.bgp([{RDF.bnode("s"), RDF.bnode("p"), RDF.bnode("o")}]) ==
               ok_bgp_struct([{RDF.bnode("s"), RDF.bnode("p"), RDF.bnode("o")}])
    end

    test "blank nodes as atoms" do
      assert Builder.bgp([{:_s, :_p, :_o}]) ==
               ok_bgp_struct([{RDF.bnode("s"), RDF.bnode("p"), RDF.bnode("o")}])
    end

    test "variable notation has precedence over blank node notation" do
      assert Builder.bgp([{:_s?, :_p?, :_o?}]) == ok_bgp_struct([{:_s, :_p, :_o}])
    end

    test "IRIs" do
      assert Builder.bgp([
               {
                 RDF.iri("http://example.com/s"),
                 RDF.iri("http://example.com/p"),
                 RDF.iri("http://example.com/o")
               }
             ]) == ok_bgp_struct([{EX.s(), EX.p(), EX.o()}])

      assert Builder.bgp([
               {
                 ~I<http://example.com/s>,
                 ~I<http://example.com/p>,
                 ~I<http://example.com/o>
               }
             ]) == ok_bgp_struct([{EX.s(), EX.p(), EX.o()}])

      assert Builder.bgp([{EX.s(), EX.p(), EX.o()}]) ==
               ok_bgp_struct([{EX.s(), EX.p(), EX.o()}])
    end

    test "vocabulary term atoms" do
      assert Builder.bgp([{EX.S, EX.P, EX.O}]) ==
               ok_bgp_struct([{RDF.iri(EX.S), RDF.iri(EX.P), RDF.iri(EX.O)}])
    end

    test "special :a atom for rdf:type" do
      assert Builder.bgp([{EX.S, :a, EX.O}]) ==
               ok_bgp_struct([{RDF.iri(EX.S), RDF.type(), RDF.iri(EX.O)}])
    end

    test "URIs" do
      assert Builder.bgp([
               {
                 URI.parse("http://example.com/s"),
                 URI.parse("http://example.com/p"),
                 URI.parse("http://example.com/o")
               }
             ]) == ok_bgp_struct([{EX.s(), EX.p(), EX.o()}])
    end

    test "literals" do
      assert Builder.bgp([{EX.s(), EX.p(), ~L"foo"}]) ==
               ok_bgp_struct([{EX.s(), EX.p(), ~L"foo"}])
    end

    test "values coercible to literals" do
      assert Builder.bgp([{EX.s(), EX.p(), "foo"}]) ==
               ok_bgp_struct([{EX.s(), EX.p(), ~L"foo"}])

      assert Builder.bgp([{EX.s(), EX.p(), 42}]) ==
               ok_bgp_struct([{EX.s(), EX.p(), RDF.literal(42)}])

      assert Builder.bgp([{EX.s(), EX.p(), true}]) ==
               ok_bgp_struct([{EX.s(), EX.p(), XSD.true()}])
    end

    test "literals on non-object positions" do
      assert {:error, %RDF.Query.InvalidError{}} = Builder.bgp([{~L"foo", EX.p(), ~L"bar"}])
    end

    test "multiple triple patterns" do
      assert Builder.bgp([
               {EX.S, EX.p(), :o?},
               {:o?, EX.p2(), 42}
             ]) ==
               ok_bgp_struct([
                 {RDF.iri(EX.S), EX.p(), :o},
                 {:o, EX.p2(), RDF.literal(42)}
               ])
    end

    test "multiple objects to the same subject-predicate" do
      result =
        ok_bgp_struct([
          {EX.s(), EX.p(), EX.o1()},
          {EX.s(), EX.p(), EX.o2()}
        ])

      assert Builder.bgp([{EX.s(), EX.p(), [EX.o1(), EX.o2()]}]) == result
      assert Builder.bgp({EX.s(), EX.p(), [EX.o1(), EX.o2()]}) == result

      assert Builder.bgp({EX.s(), EX.p(), [:o?, false, 42, "foo"]}) ==
               ok_bgp_struct([
                 {EX.s(), EX.p(), :o},
                 {EX.s(), EX.p(), XSD.false()},
                 {EX.s(), EX.p(), RDF.literal(42)},
                 {EX.s(), EX.p(), RDF.literal("foo")}
               ])
    end

    test "multiple predicate-object pairs to the same subject" do
      result =
        ok_bgp_struct([
          {EX.s(), EX.p1(), EX.o1()},
          {EX.s(), EX.p2(), EX.o2()}
        ])

      assert Builder.bgp([
               {
                 EX.s(),
                 [
                   {EX.p1(), EX.o1()},
                   {EX.p2(), EX.o2()}
                 ]
               }
             ]) == result

      assert Builder.bgp([
               {
                 EX.s(),
                 [
                   {:a, :o?},
                   {EX.p1(), [42, 3.14]},
                   {EX.p2(), ["foo", true]}
                 ]
               }
             ]) ==
               ok_bgp_struct([
                 {EX.s(), RDF.type(), :o},
                 {EX.s(), EX.p1(), RDF.literal(42)},
                 {EX.s(), EX.p1(), RDF.literal(3.14)},
                 {EX.s(), EX.p2(), RDF.literal("foo")},
                 {EX.s(), EX.p2(), XSD.true()}
               ])

      assert Builder.bgp([{EX.s(), {EX.p(), EX.o()}}]) ==
               ok_bgp_struct([{EX.s(), EX.p(), EX.o()}])
    end

    test "triple patterns with maps" do
      assert Builder.bgp(%{
               EX.S => {EX.p(), :o?},
               o?: [
                 {EX.p2(), 42},
                 {EX.p3(), "foo"}
               ]
             }) ==
               ok_bgp_struct([
                 {RDF.iri(EX.S), EX.p(), :o},
                 {:o, EX.p2(), RDF.literal(42)},
                 {:o, EX.p3(), RDF.literal("foo")}
               ])

      assert Builder.bgp(%{
               EX.s() => %{
                 :a => :o1?,
                 :p? => :o2?,
                 EX.p1() => [42, 3.14],
                 EX.p2() => ["foo", true]
               }
             }) ==
               ok_bgp_struct([
                 {EX.s(), RDF.type(), :o1},
                 {EX.s(), :p, :o2},
                 {EX.s(), EX.p1(), RDF.literal(42)},
                 {EX.s(), EX.p1(), RDF.literal(3.14)},
                 {EX.s(), EX.p2(), RDF.literal("foo")},
                 {EX.s(), EX.p2(), XSD.true()}
               ])

      assert Builder.bgp([
               %{EX.S => {EX.p(), :o?}},
               {EX.S2, EX.p(), :o?}
             ]) ==
               ok_bgp_struct([
                 {RDF.iri(EX.S), EX.p(), :o},
                 {RDF.iri(EX.S2), EX.p(), :o}
               ])
    end

    test "triple patterns with descriptions" do
      assert Builder.bgp([
               EX.p(~B"s", EX.O),
               {:_s, :p?, :o?}
             ]) ==
               ok_bgp_struct([
                 {~B"s", EX.p(), RDF.iri(EX.O)},
                 {~B"s", :p, :o}
               ])
    end

    test "with contexts" do
      assert Builder.bgp(
               %{
                 s?: %{
                   p1: :o?,
                   p2: [42, true]
                 },
                 o?: [p3: ["foo", "bar"]]
               },
               context: %{
                 p1: EX.p1(),
                 p2: EX.p2(),
                 p3: EX.p3()
               }
             ) ==
               ok_bgp_struct([
                 {:o, EX.p3(), ~L"foo"},
                 {:o, EX.p3(), ~L"bar"},
                 {:s, EX.p1(), :o},
                 {:s, EX.p2(), XSD.integer(42)},
                 {:s, EX.p2(), XSD.true()}
               ])
    end
  end

  describe "path/2" do
    test "element count == 3" do
      assert Builder.path([EX.s(), EX.p(), EX.o()]) == ok_bgp_struct([{EX.s(), EX.p(), EX.o()}])
      assert Builder.path([:s?, :p?, :o?]) == ok_bgp_struct([{:s, :p, :o}])
    end

    test "element count > 3" do
      assert Builder.path([EX.s(), EX.p1(), EX.p2(), EX.o()]) ==
               ok_bgp_struct([
                 {EX.s(), EX.p1(), RDF.bnode("b0")},
                 {RDF.bnode("b0"), EX.p2(), EX.o()}
               ])

      assert Builder.path([:s?, :p1?, :p2?, :o?]) ==
               ok_bgp_struct([
                 {:s, :p1, RDF.bnode("b0")},
                 {RDF.bnode("b0"), :p2, :o}
               ])
    end

    test "element count < 3" do
      assert {:error, %RDF.Query.InvalidError{}} = Builder.path([EX.s(), EX.p()])
      assert {:error, %RDF.Query.InvalidError{}} = Builder.path([EX.s()])
      assert {:error, %RDF.Query.InvalidError{}} = Builder.path([])
    end

    test "with_elements: true" do
      assert Builder.path([EX.s(), EX.p1(), EX.p2(), :o?], with_elements: true) ==
               ok_bgp_struct([
                 {EX.s(), EX.p1(), :el0},
                 {:el0, EX.p2(), :o}
               ])
    end

    test "with contexts" do
      property_map = %{
        p1: EX.p1(),
        p2: EX.p2()
      }

      assert Builder.path([EX.s(), :p1, :p2, EX.o()], context: property_map) ==
               ok_bgp_struct([
                 {EX.s(), EX.p1(), RDF.bnode("b0")},
                 {RDF.bnode("b0"), EX.p2(), EX.o()}
               ])

      assert Builder.path([EX.s(), :p1, :p2, :o?], context: property_map, with_elements: true) ==
               ok_bgp_struct([
                 {EX.s(), EX.p1(), :el0},
                 {:el0, EX.p2(), :o}
               ])
    end
  end
end
