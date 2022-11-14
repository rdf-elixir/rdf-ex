defmodule RDF.Query.BuilderStarTest do
  use RDF.Query.Test.Case

  alias RDF.Query.Builder

  describe "bgp/1" do
    test "variables" do
      assert Builder.bgp([{{:as1?, :ap1?, :ao1?}, :p?, {:as2?, :ap2?, :ao2?}}]) ==
               ok_bgp_struct([{{:as1, :ap1, :ao1}, :p, {:as2, :ap2, :ao2}}])
    end

    test "blank nodes" do
      assert Builder.bgp([
               {{RDF.bnode("as1"), RDF.bnode("ap1"), RDF.bnode("ao1")}, RDF.bnode("p"),
                {RDF.bnode("as2"), RDF.bnode("ap2"), RDF.bnode("ao2")}}
             ]) ==
               ok_bgp_struct([
                 {{RDF.bnode("as1"), RDF.bnode("ap1"), RDF.bnode("ao1")}, RDF.bnode("p"),
                  {RDF.bnode("as2"), RDF.bnode("ap2"), RDF.bnode("ao2")}}
               ])
    end

    test "blank nodes as atoms" do
      assert Builder.bgp([{{:_as1, :_ap1, :_ao1}, :_p, {:_as2, :_ap2, :_ao2}}]) ==
               ok_bgp_struct([
                 {{RDF.bnode("as1"), RDF.bnode("ap1"), RDF.bnode("ao1")}, RDF.bnode("p"),
                  {RDF.bnode("as2"), RDF.bnode("ap2"), RDF.bnode("ao2")}}
               ])
    end

    test "variable notation has precedence over blank node notation" do
      assert Builder.bgp([{{:_as1?, :_ap1?, :_ao1?}, :_p?, {:_as2?, :_ap2?, :_ao2?}}]) ==
               ok_bgp_struct([{{:_as1, :_ap1, :_ao1}, :_p, {:_as2, :_ap2, :_ao2}}])
    end

    test "various RDF terms" do
      assert Builder.bgp([
               {{EX.AS, :a, ~I<http://example.com/ao>}, EX.p(),
                {URI.parse("http://example.com/as"), EX.ap(), 42}}
             ]) ==
               ok_bgp_struct([
                 {{RDF.iri(EX.AS), RDF.type(), EX.ao()}, EX.p(),
                  {EX.as(), EX.ap(), XSD.integer(42)}}
               ])
    end

    test "literals on non-object positions" do
      assert {:error, %RDF.Query.InvalidError{}} =
               Builder.bgp([{{~L"foo", EX.p(), ~L"bar"}, EX.p(), EX.o()}])
    end

    test "multiple objects to the same subject-predicate" do
      assert Builder.bgp([
               {{EX.as(), EX.ap(), EX.ao()}, EX.p(),
                [{EX.s(), EX.p(), EX.o1()}, {EX.s(), EX.p(), EX.o2()}]}
             ]) ==
               ok_bgp_struct([
                 {{EX.as(), EX.ap(), EX.ao()}, EX.p(), {EX.s(), EX.p(), EX.o1()}},
                 {{EX.as(), EX.ap(), EX.ao()}, EX.p(), {EX.s(), EX.p(), EX.o2()}}
               ])
    end

    test "multiple predicate-object pairs to the same subject" do
      assert Builder.bgp([
               {{EX.as(), EX.ap(), EX.ao()},
                [
                  {EX.p1(), {EX.s(), EX.p(), EX.o1()}},
                  {EX.p2(), {EX.s(), EX.p(), EX.o2()}}
                ]}
             ]) ==
               ok_bgp_struct([
                 {{EX.as(), EX.ap(), EX.ao()}, EX.p1(), {EX.s(), EX.p(), EX.o1()}},
                 {{EX.as(), EX.ap(), EX.ao()}, EX.p2(), {EX.s(), EX.p(), EX.o2()}}
               ])

      assert Builder.bgp([{{EX.as(), EX.ap(), EX.ao()}, {EX.p1(), {EX.s(), EX.p(), EX.o1()}}}]) ==
               ok_bgp_struct([{{EX.as(), EX.ap(), EX.ao()}, EX.p1(), {EX.s(), EX.p(), EX.o1()}}])
    end

    test "triple patterns with maps" do
      assert Builder.bgp(%{
               {EX.as(), EX.ap(), EX.ao1()} => %{EX.p1() => {EX.s(), EX.p(), EX.o1()}},
               {EX.as(), EX.ap(), EX.ao2()} => {EX.p2(), {EX.s(), EX.p(), EX.o2()}}
             }) ==
               ok_bgp_struct([
                 {{EX.as(), EX.ap(), EX.ao1()}, EX.p1(), {EX.s(), EX.p(), EX.o1()}},
                 {{EX.as(), EX.ap(), EX.ao2()}, EX.p2(), {EX.s(), EX.p(), EX.o2()}}
               ])
    end

    test "with contexts" do
      assert Builder.bgp(
               %{
                 {EX.as(), :ap, EX.ao1()} => %{p1: {EX.s(), :p, EX.o1()}},
                 {EX.as(), :ap, EX.ao2()} => {:p2, {EX.s(), :p, EX.o2()}}
               },
               context: %{
                 p: EX.p(),
                 ap: EX.ap(),
                 p1: EX.p1(),
                 p2: EX.p2()
               }
             ) ==
               ok_bgp_struct([
                 {{EX.as(), EX.ap(), EX.ao1()}, EX.p1(), {EX.s(), EX.p(), EX.o1()}},
                 {{EX.as(), EX.ap(), EX.ao2()}, EX.p2(), {EX.s(), EX.p(), EX.o2()}}
               ])
    end

    test "with deeply nested quoted triples" do
      assert Builder.bgp([
               {
                 {{:a?, :b?, :_c}, :d?, :e?},
                 :f?,
                 {{{:g?, :h?, {EX.I, :j?, "k"}}, :m?, :n?}, :o?, :p?}
               }
             ]) ==
               ok_bgp_struct([
                 {
                   {{:a, :b, ~B"c"}, :d, :e},
                   :f,
                   {{{:g, :h, {RDF.iri(EX.I), :j, ~L"k"}}, :m, :n}, :o, :p}
                 }
               ])
    end
  end

  test "path/2" do
    assert Builder.path([
             {EX.as(), EX.ap(), EX.ao1()},
             EX.p1(),
             EX.p2(),
             {EX.as(), EX.ap(), EX.ao2()}
           ]) ==
             ok_bgp_struct([
               {{EX.as(), EX.ap(), EX.ao1()}, EX.p1(), RDF.bnode("b0")},
               {RDF.bnode("b0"), EX.p2(), {EX.as(), EX.ap(), EX.ao2()}}
             ])
  end
end
