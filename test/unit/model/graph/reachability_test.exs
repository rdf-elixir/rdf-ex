defmodule RDF.Graph.ReachabilityTest do
  use RDF.Test.Case

  doctest RDF.Graph.Reachability

  describe "reachable/3 with custom follow function" do
    test "single node without outgoing edges" do
      graph =
        Graph.new([
          {EX.A, EX.p1(), EX.B}
        ])

      assert Graph.reachable(graph, EX.A, fn _, _, _ -> true end) ==
               Graph.new([{EX.A, EX.p1(), EX.B}])
    end

    test "simple chain A→B→C with follow all" do
      graph =
        Graph.new([
          {EX.A, EX.p1(), EX.B},
          {EX.B, EX.p2(), EX.C},
          {EX.C, EX.p3(), EX.D},
          {EX.Other, EX.p(), EX.Other}
        ])

      assert Graph.reachable(graph, EX.A, fn _, _, _ -> true end) ==
               Graph.new([
                 {EX.A, EX.p1(), EX.B},
                 {EX.B, EX.p2(), EX.C},
                 {EX.C, EX.p3(), EX.D}
               ])
    end

    test "cycle detection A→B→C→A" do
      graph =
        Graph.new([
          {EX.A, EX.p1(), EX.B},
          {EX.B, EX.p2(), EX.C},
          {EX.C, EX.p3(), EX.A},
          {EX.Other, EX.p(), EX.Other}
        ])

      assert Graph.reachable(graph, EX.A, fn _, _, _ -> true end) ==
               Graph.new([
                 {EX.A, EX.p1(), EX.B},
                 {EX.B, EX.p2(), EX.C},
                 {EX.C, EX.p3(), EX.A}
               ])
    end

    test "depth parameter passed correctly" do
      graph =
        Graph.new([
          {EX.A, EX.p(), EX.B},
          {EX.B, EX.p(), EX.C},
          {EX.C, EX.p(), EX.D},
          {EX.D, EX.p(), EX.E}
        ])

      # Only follow nodes at depth <= 2
      result = Graph.reachable(graph, EX.A, fn _obj, _pred, depth -> depth <= 2 end)

      # A (depth 0), B (depth 1), C (depth 2) are visited, so all their triples are included
      # D (depth 3) is NOT visited
      assert result ==
               Graph.new([
                 {EX.A, EX.p(), EX.B},
                 {EX.B, EX.p(), EX.C},
                 {EX.C, EX.p(), EX.D}
               ])
    end

    test "predicate parameter passed correctly" do
      graph =
        Graph.new([
          {EX.A, EX.p1(), EX.B},
          {EX.A, EX.p2(), EX.C},
          {EX.B, EX.p(), EX.X},
          {EX.C, EX.p(), EX.D}
        ])

      assert Graph.reachable(graph, EX.A, fn _obj, pred, _depth -> pred == EX.p1() end) ==
               Graph.new([
                 {EX.A, EX.p1(), EX.B},
                 {EX.A, EX.p2(), EX.C},
                 {EX.B, EX.p(), EX.X}
               ])
    end

    test "follow function decides traversal" do
      graph =
        Graph.new([
          {EX.A, EX.p1(), EX.B},
          {EX.A, EX.p2(), EX.C},
          {EX.B, EX.p3(), EX.D},
          {EX.C, EX.p4(), EX.E}
        ])

      assert Graph.reachable(graph, EX.A, fn _obj, pred, _depth -> pred == EX.p1() end) ==
               Graph.new([
                 {EX.A, EX.p1(), EX.B},
                 {EX.A, EX.p2(), EX.C},
                 {EX.B, EX.p3(), EX.D}
               ])
    end
  end

  describe "reachable/3 with keyword options" do
    test "follow: :all - complete reachability" do
      graph =
        Graph.new([
          {EX.A, EX.p1(), EX.B},
          {EX.B, EX.p2(), EX.C},
          {EX.C, EX.p3(), EX.D},
          {EX.Other, EX.p(), EX.Other}
        ])

      assert Graph.reachable(graph, EX.A, follow: :all) ==
               Graph.new([
                 {EX.A, EX.p1(), EX.B},
                 {EX.B, EX.p2(), EX.C},
                 {EX.C, EX.p3(), EX.D}
               ])
    end

    test "follow: :bnodes - only follow blank nodes" do
      graph =
        Graph.new([
          {EX.A, EX.p1(), ~B<b1>},
          {EX.A, EX.p2(), EX.B},
          {~B<b1>, EX.p3(), ~B<b2>},
          {~B<b1>, EX.p4(), EX.C},
          {~B<b2>, EX.p5(), EX.D},
          {EX.B, EX.p6(), ~B<b3>},
          {EX.B, EX.p7(), EX.E}
        ])

      assert Graph.reachable(graph, EX.A, follow: :bnodes) ==
               Graph.new([
                 {EX.A, EX.p1(), ~B<b1>},
                 {EX.A, EX.p2(), EX.B},
                 {~B<b1>, EX.p3(), ~B<b2>},
                 {~B<b1>, EX.p4(), EX.C},
                 {~B<b2>, EX.p5(), EX.D}
               ])
    end

    test "max_depth option" do
      graph =
        Graph.new([
          {EX.A, EX.p(), EX.B},
          {EX.B, EX.p(), EX.C},
          {EX.C, EX.p(), EX.D},
          {EX.D, EX.p(), EX.E}
        ])

      # A (depth 0), B (depth 1), C (depth 2) visited; D (depth 3) not visited
      assert Graph.reachable(graph, EX.A, max_depth: 2) ==
               Graph.new([
                 {EX.A, EX.p(), EX.B},
                 {EX.B, EX.p(), EX.C},
                 {EX.C, EX.p(), EX.D}
               ])
    end

    test "predicates filter option" do
      graph =
        Graph.new([
          {EX.A, EX.p1(), EX.B},
          {EX.A, EX.p2(), EX.C},
          {EX.B, EX.p1(), EX.D},
          {EX.B, EX.p2(), EX.E},
          {EX.C, EX.p1(), EX.F},
          {EX.F, EX.p(), EX.G}
        ])

      assert Graph.reachable(graph, EX.A, follow: :all, predicates: [EX.p1()]) ==
               Graph.new([
                 {EX.A, EX.p1(), EX.B},
                 {EX.A, EX.p2(), EX.C},
                 {EX.B, EX.p1(), EX.D},
                 {EX.B, EX.p2(), EX.E}
               ])
    end

    test "combined options: blank_nodes + max_depth" do
      graph =
        Graph.new([
          {EX.A, EX.p(), ~B<b1>},
          {~B<b1>, EX.p(), ~B<b2>},
          {~B<b2>, EX.p(), ~B<b3>},
          {~B<b3>, EX.p(), ~B<b4>}
        ])

      # A (depth 0), b1 (depth 1), b2 (depth 2) visited; b3 (depth 3) not visited
      assert Graph.reachable(graph, EX.A, follow: :bnodes, max_depth: 2) ==
               Graph.new([
                 {EX.A, EX.p(), ~B<b1>},
                 {~B<b1>, EX.p(), ~B<b2>},
                 {~B<b2>, EX.p(), ~B<b3>}
               ])
    end

    test "combined options: all + max_depth + predicates" do
      graph =
        Graph.new([
          {EX.A, EX.p1(), EX.B},
          {EX.A, EX.p2(), EX.C},
          {EX.B, EX.p1(), EX.D},
          {EX.B, EX.p2(), EX.E},
          {EX.C, EX.p1(), EX.F},
          {EX.D, EX.p1(), EX.G},
          {EX.E, EX.p(), EX.H},
          {EX.F, EX.p(), EX.I},
          {EX.G, EX.p(), EX.J}
        ])

      # A (depth 0), B (depth 1 via p1), D (depth 2 via p1) visited
      # C not visited (p2 not in predicates), E not visited (p2), F not visited (depth 3), G not visited (depth 3)
      assert Graph.reachable(graph, EX.A, follow: :all, max_depth: 2, predicates: [EX.p1()]) ==
               Graph.new([
                 {EX.A, EX.p1(), EX.B},
                 {EX.A, EX.p2(), EX.C},
                 {EX.B, EX.p1(), EX.D},
                 {EX.B, EX.p2(), EX.E},
                 {EX.D, EX.p1(), EX.G}
               ])
    end

    test "bnode_depth: :unlimited with max_depth" do
      graph =
        Graph.new([
          {EX.A, EX.p(), ~B<b1>},
          {~B<b1>, EX.p(), EX.B},
          {EX.B, EX.p(), ~B<b2>},
          {~B<b2>, EX.p(), ~B<b3>},
          {~B<b3>, EX.p(), EX.C},
          {EX.C, EX.p(), EX.D}
        ])

      # A (depth 0), b1 (depth 1 bnode), B (depth 2 IRI - at limit), b2 (depth 3 bnode - unlimited)
      # b3 (depth 4 bnode - unlimited), C (depth 5 IRI - exceeds max_depth) not visited
      assert Graph.reachable(graph, EX.A, max_depth: 2, bnode_depth: :unlimited) ==
               Graph.new([
                 {EX.A, EX.p(), ~B<b1>},
                 {~B<b1>, EX.p(), EX.B},
                 {EX.B, EX.p(), ~B<b2>},
                 {~B<b2>, EX.p(), ~B<b3>},
                 {~B<b3>, EX.p(), EX.C}
               ])
    end

    test "bnode_depth with different limit than max_depth" do
      graph =
        Graph.new([
          {EX.A, EX.p(), EX.B},
          {EX.A, EX.q(), ~B<b1>},
          {EX.B, EX.p(), ~B<b2>},
          {~B<b1>, EX.p(), ~B<b3>},
          {~B<b2>, EX.p(), EX.C},
          {~B<b3>, EX.p(), ~B<b4>},
          {~B<b4>, EX.p(), EX.D},
          {~B<b4>, EX.p(), ~B<b5>},
          {~B<b5>, EX.p(), ~B<b6>}
        ])

      assert Graph.reachable(graph, EX.A, max_depth: 1, bnode_depth: 3) ==
               Graph.new([
                 {EX.A, EX.p(), EX.B},
                 {EX.A, EX.q(), ~B<b1>},
                 {EX.B, EX.p(), ~B<b2>},
                 {~B<b1>, EX.p(), ~B<b3>},
                 {~B<b3>, EX.p(), ~B<b4>},
                 {~B<b4>, EX.p(), EX.D},
                 {~B<b4>, EX.p(), ~B<b5>}
               ])
    end

    test "bnode_depth with mixed blank nodes and IRIs at various depths" do
      graph =
        Graph.new([
          {EX.A, EX.p(), ~B<b1>},
          {~B<b1>, EX.p(), EX.B},
          {~B<b1>, EX.q(), ~B<b2>},
          {EX.B, EX.p(), EX.C},
          {~B<b2>, EX.p(), ~B<b3>},
          {~B<b3>, EX.p(), EX.D},
          {EX.C, EX.p(), ~B<b4>},
          {EX.D, EX.p(), EX.E}
        ])

      # A (depth 0), b1 (depth 1 bnode), B (depth 2 IRI), b2 (depth 2 bnode), C (depth 3 IRI - exceeds)
      # b3 (depth 3 bnode - exceeds bnode_depth), b4 not visited
      assert Graph.reachable(graph, EX.A, max_depth: 2, bnode_depth: 2) ==
               Graph.new([
                 {EX.A, EX.p(), ~B<b1>},
                 {~B<b1>, EX.p(), EX.B},
                 {~B<b1>, EX.q(), ~B<b2>},
                 {EX.B, EX.p(), EX.C},
                 {~B<b2>, EX.p(), ~B<b3>}
               ])
    end

    test "into: write into existing graph" do
      graph =
        Graph.new([
          {EX.A, EX.p(), EX.B},
          {EX.B, EX.p(), EX.C},
          {EX.Other, EX.p(), EX.Other}
        ])

      existing = Graph.new({EX.X, EX.other(), EX.Y})

      assert Graph.reachable(graph, EX.A, into: existing) ==
               Graph.new([
                 {EX.X, EX.other(), EX.Y},
                 {EX.A, EX.p(), EX.B},
                 {EX.B, EX.p(), EX.C}
               ])
    end

    test "into: preserve graph metadata" do
      prefixes = RDF.PrefixMap.new(ex: EX)
      base_iri = ~I<http://base.example.com/>

      graph =
        Graph.new(
          [
            {EX.A, EX.p(), EX.B},
            {EX.Other, EX.p(), EX.Other}
          ],
          prefixes: prefixes,
          base_iri: base_iri
        )

      result = Graph.reachable(graph, EX.A, into: Graph.clear(graph))

      assert result.descriptions == Graph.new({EX.A, EX.p(), EX.B}).descriptions
      assert result.prefixes == prefixes
      assert result.base_iri == base_iri
    end

    test "into: combined with custom follow function" do
      graph =
        Graph.new([
          {EX.A, EX.p1(), EX.B},
          {EX.A, EX.p2(), EX.C},
          {EX.B, EX.p(), EX.D},
          {EX.C, EX.p(), EX.E}
        ])

      existing = Graph.new({EX.X, EX.other(), EX.Y})

      result =
        Graph.reachable(graph, EX.A,
          follow: fn _obj, pred, _depth -> pred == EX.p1() end,
          into: existing
        )

      assert result ==
               Graph.new([
                 {EX.X, EX.other(), EX.Y},
                 {EX.A, EX.p1(), EX.B},
                 {EX.A, EX.p2(), EX.C},
                 {EX.B, EX.p(), EX.D}
               ])
    end

    test "into: with pre-existing node in traversal path" do
      graph =
        Graph.new([
          {EX.A, EX.p(), EX.B},
          {EX.B, EX.p(), EX.C}
        ])

      # EX.B is in the traversal path but also pre-exists in the into graph
      existing = Graph.new({EX.B, EX.other(), EX.Other})

      # Should still traverse through EX.B to reach EX.C
      assert Graph.reachable(graph, EX.A, into: existing) ==
               Graph.new([
                 {EX.B, EX.other(), EX.Other},
                 {EX.A, EX.p(), EX.B},
                 {EX.B, EX.p(), EX.C}
               ])
    end
  end

  describe "reachable/3 edge cases" do
    test "coercible start node (namespace term)" do
      graph =
        Graph.new([
          {EX.A, EX.p(), EX.B},
          {EX.B, EX.p(), EX.C}
        ])

      assert Graph.reachable(graph, EX.A) ==
               Graph.new([
                 {EX.A, EX.p(), EX.B},
                 {EX.B, EX.p(), EX.C}
               ])
    end

    test "start node not in graph" do
      graph = Graph.new([{EX.A, EX.p(), EX.B}])

      assert Graph.reachable(graph, EX.NotInGraph) == Graph.new()
    end

    test "multiple paths to same node" do
      graph =
        Graph.new([
          {EX.A, EX.p1(), EX.B},
          {EX.A, EX.p2(), EX.C},
          {EX.B, EX.p3(), EX.D},
          {EX.C, EX.p4(), EX.D},
          {EX.D, EX.p5(), EX.E}
        ])

      assert Graph.reachable(graph, EX.A) ==
               Graph.new([
                 {EX.A, EX.p1(), EX.B},
                 {EX.A, EX.p2(), EX.C},
                 {EX.B, EX.p3(), EX.D},
                 {EX.C, EX.p4(), EX.D},
                 {EX.D, EX.p5(), EX.E}
               ])
    end

    test "blank nodes with cycles" do
      graph =
        Graph.new([
          {EX.A, EX.p(), ~B<b1>},
          {~B<b1>, EX.p(), ~B<b2>},
          {~B<b2>, EX.p(), ~B<b1>},
          {~B<b2>, EX.other(), EX.B},
          {EX.B, EX.p(), EX.C}
        ])

      assert Graph.reachable(graph, EX.A, follow: :bnodes) ==
               Graph.new([
                 {EX.A, EX.p(), ~B<b1>},
                 {~B<b1>, EX.p(), ~B<b2>},
                 {~B<b2>, EX.p(), ~B<b1>},
                 {~B<b2>, EX.other(), EX.B}
               ])
    end

    test "graph with literals at object position" do
      graph =
        Graph.new([
          {EX.A, EX.p(), EX.B},
          {EX.A, EX.label(), ~L"Label A"},
          {EX.B, EX.p(), EX.C},
          {EX.B, EX.label(), ~L"Label B"},
          {EX.C, EX.value(), 42}
        ])

      # Literals should not cause errors, they are simply not followed
      assert Graph.reachable(graph, EX.A, follow: :all) ==
               Graph.new([
                 {EX.A, EX.p(), EX.B},
                 {EX.A, EX.label(), ~L"Label A"},
                 {EX.B, EX.p(), EX.C},
                 {EX.B, EX.label(), ~L"Label B"},
                 {EX.C, EX.value(), 42}
               ])
    end

    @tag rdf_star: true
    test "RDF-star: triple as subject" do
      triple = {EX.s(), EX.p(), EX.o()}

      graph =
        Graph.new([
          {triple, EX.certainty(), 0.9},
          {triple, EX.source(), EX.Wikipedia},
          {EX.Wikipedia, EX.url(), ~I<http://wikipedia.org>},
          {EX.Other, EX.unrelated(), EX.X}
        ])

      assert Graph.reachable(graph, triple, follow: :all) ==
               Graph.new([
                 {triple, EX.certainty(), 0.9},
                 {triple, EX.source(), EX.Wikipedia},
                 {EX.Wikipedia, EX.url(), ~I<http://wikipedia.org>}
               ])
    end

    @tag rdf_star: true
    test "RDF-star: coercible triple as subject" do
      graph =
        Graph.new([
          {{EX.S, EX.p(), EX.O}, EX.certainty(), 0.9},
          {{EX.S, EX.p(), EX.O}, EX.source(), EX.Wikipedia},
          {EX.Wikipedia, EX.url(), ~I<http://wikipedia.org>}
        ])

      assert Graph.reachable(graph, {EX.S, EX.p(), EX.O}, follow: :all) ==
               Graph.new([
                 {{EX.S, EX.p(), EX.O}, EX.certainty(), 0.9},
                 {{EX.S, EX.p(), EX.O}, EX.source(), EX.Wikipedia},
                 {EX.Wikipedia, EX.url(), ~I<http://wikipedia.org>}
               ])
    end

    test "error: follow function with other options" do
      graph = Graph.new({EX.A, EX.p(), EX.B})

      assert_raise ArgumentError,
                   ~r/follow function cannot be combined with other options/i,
                   fn ->
                     Graph.reachable(graph, EX.A, follow: fn _, _, _ -> true end, max_depth: 2)
                   end
    end

    test "error: follow function with wrong arity" do
      graph = Graph.new({EX.A, EX.p(), EX.B})

      assert_raise ArgumentError, ~r/follow function must have arity 3/i, fn ->
        Graph.reachable(graph, EX.A, follow: fn _ -> true end)
      end
    end
  end
end
