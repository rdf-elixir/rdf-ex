defmodule RDF.GraphTest do
  use RDF.Test.Case

  doctest RDF.Graph


  describe "new" do
    test "creating an empty unnamed graph" do
      assert unnamed_graph?(unnamed_graph())
    end

    test "creating an empty graph with a proper graph name" do
      refute unnamed_graph?(named_graph())
      assert named_graph?(named_graph())
    end

    test "creating an empty graph with a blank node as graph name" do
      assert named_graph(bnode("graph_name"))
             |> named_graph?(bnode("graph_name"))
    end

    test "creating an empty graph with a coercible graph name" do
      assert named_graph("http://example.com/graph/GraphName")
             |> named_graph?(iri("http://example.com/graph/GraphName"))
      assert named_graph(EX.Foo) |> named_graph?(iri(EX.Foo))
    end

    test "creating an unnamed graph with an initial triple" do
      g = Graph.new({EX.Subject, EX.predicate, EX.Object})
      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})

      g = Graph.new(EX.Subject, EX.predicate, EX.Object)
      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating a named graph with an initial triple" do
      g = Graph.new(EX.GraphName, {EX.Subject, EX.predicate, EX.Object})
      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})

      g = Graph.new(EX.GraphName, EX.Subject, EX.predicate, EX.Object)
      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating an unnamed graph with a list of initial triples" do
      g = Graph.new([{EX.Subject1, EX.predicate1, EX.Object1},
                     {EX.Subject2, EX.predicate2, EX.Object2}])
      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1, EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject2, EX.predicate2, EX.Object2})

      g = Graph.new(EX.Subject, EX.predicate, [EX.Object1, EX.Object2])
      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object2})
    end

    test "creating a named graph with a list of initial triples" do
      g = Graph.new(EX.GraphName, [{EX.Subject, EX.predicate1, EX.Object1},
                                   {EX.Subject, EX.predicate2, EX.Object2}])
      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate1, EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate2, EX.Object2})

      g = Graph.new(EX.GraphName, EX.Subject, EX.predicate, [EX.Object1, EX.Object2])
      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object2})
    end

    test "creating a named graph with an initial description" do
      g = Graph.new(EX.GraphName, Description.new({EX.Subject, EX.predicate, EX.Object}))
      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating an unnamed graph with an initial description" do
      g = Graph.new(Description.new({EX.Subject, EX.predicate, EX.Object}))
      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating a named graph from another graph" do
      g = Graph.new(EX.GraphName, Graph.new({EX.Subject, EX.predicate, EX.Object}))
      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})

      g = Graph.new(EX.GraphName, Graph.new(EX.OtherGraphName, {EX.Subject, EX.predicate, EX.Object}))
      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating an unnamed graph from another graph" do
      g = Graph.new(Graph.new({EX.Subject, EX.predicate, EX.Object}))
      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})

      g = Graph.new(Graph.new(EX.OtherGraphName, {EX.Subject, EX.predicate, EX.Object}))
      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})
    end
  end

  describe "add" do
    test "a proper triple" do
      assert Graph.add(graph(), iri(EX.Subject), EX.predicate, iri(EX.Object))
        |> graph_includes_statement?({EX.Subject, EX.predicate, EX.Object})
      assert Graph.add(graph(), {iri(EX.Subject), EX.predicate, iri(EX.Object)})
        |> graph_includes_statement?({EX.Subject, EX.predicate, EX.Object})
    end

    test "a coercible triple" do
      assert Graph.add(graph(),
          "http://example.com/Subject", EX.predicate, EX.Object)
        |> graph_includes_statement?({EX.Subject, EX.predicate, EX.Object})
      assert Graph.add(graph(),
          {"http://example.com/Subject", EX.predicate, EX.Object})
        |> graph_includes_statement?({EX.Subject, EX.predicate, EX.Object})
    end

    test "a triple with multiple objects" do
      g = Graph.add(graph(), EX.Subject1, EX.predicate1, [EX.Object1, EX.Object2])
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1, EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1, EX.Object2})
    end

    test "a list of triples" do
      g = Graph.add(graph(), [
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
        {EX.Subject3, EX.predicate3, EX.Object3}
      ])
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1, EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate2, EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject3, EX.predicate3, EX.Object3})
    end

    test "a Description" do
      g = Graph.add(graph(), Description.new(EX.Subject1, [
        {EX.predicate1, EX.Object1},
        {EX.predicate2, EX.Object2},
      ]))
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1, EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate2, EX.Object2})

      g = Graph.add(g, Description.new({EX.Subject1, EX.predicate3, EX.Object3}))
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1, EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate2, EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate3, EX.Object3})
    end

    test "a list of Descriptions" do
      g = Graph.add(graph(), [
        Description.new({EX.Subject1, EX.predicate1, EX.Object1}),
        Description.new({EX.Subject2, EX.predicate2, EX.Object2}),
        Description.new({EX.Subject1, EX.predicate3, EX.Object3})
      ])
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1, EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject2, EX.predicate2, EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate3, EX.Object3})
    end

    test "duplicates are ignored" do
      g = Graph.add(graph(), {EX.Subject, EX.predicate, EX.Object})
      assert Graph.add(g, {EX.Subject, EX.predicate, EX.Object}) == g
    end

    test "a Graph" do
      g = Graph.add(graph(), Graph.new([
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject2, EX.predicate2, EX.Object2},
        {EX.Subject3, EX.predicate3, EX.Object3}
      ]))
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1, EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject2, EX.predicate2, EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject3, EX.predicate3, EX.Object3})

      g = Graph.add(g, Graph.new([
        {EX.Subject1, EX.predicate1, EX.Object2},
        {EX.Subject2, EX.predicate4, EX.Object4},
      ]))
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1, EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1, EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject2, EX.predicate2, EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject2, EX.predicate4, EX.Object4})
      assert graph_includes_statement?(g, {EX.Subject3, EX.predicate3, EX.Object3})
    end

    test "non-coercible Triple elements are causing an error" do
      assert_raise RDF.IRI.InvalidError, fn ->
        Graph.add(graph(), {"not a IRI", EX.predicate, iri(EX.Object)})
      end
      assert_raise RDF.Literal.InvalidError, fn ->
        Graph.add(graph(), {EX.Subject, EX.prop, self()})
      end
    end
  end


  describe "put" do
    test "a list of triples" do
      g = Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}])
        |> RDF.Graph.put([{EX.S1, EX.P2, EX.O3}, {EX.S1, EX.P2, bnode(:foo)},
                          {EX.S2, EX.P2, EX.O3}, {EX.S2, EX.P2, EX.O4}])

        assert Graph.triple_count(g) == 5
        assert graph_includes_statement?(g, {EX.S1, EX.P1, EX.O1})
        assert graph_includes_statement?(g, {EX.S1, EX.P2, EX.O3})
        assert graph_includes_statement?(g, {EX.S1, EX.P2, bnode(:foo)})
        assert graph_includes_statement?(g, {EX.S2, EX.P2, EX.O3})
        assert graph_includes_statement?(g, {EX.S2, EX.P2, EX.O4})
    end

    test "a Description" do
      g = Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}, {EX.S1, EX.P3, EX.O3}])
        |> RDF.Graph.put(Description.new(EX.S1, [{EX.P3, EX.O4}, {EX.P2, bnode(:foo)}]))

      assert Graph.triple_count(g) == 4
      assert graph_includes_statement?(g, {EX.S1, EX.P1, EX.O1})
      assert graph_includes_statement?(g, {EX.S1, EX.P3, EX.O4})
      assert graph_includes_statement?(g, {EX.S1, EX.P2, bnode(:foo)})
      assert graph_includes_statement?(g, {EX.S2, EX.P2, EX.O2})
    end

    test "a Graph" do
      g =
        Graph.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S1, EX.P3, EX.O3},
          {EX.S2, EX.P2, EX.O2},
        ])
        |> RDF.Graph.put(Graph.new([
          {EX.S1, EX.P3, EX.O4},
          {EX.S2, EX.P2, bnode(:foo)},
          {EX.S3, EX.P3, EX.O3}
        ]))

      assert Graph.triple_count(g) == 4
      assert graph_includes_statement?(g, {EX.S1, EX.P1, EX.O1})
      assert graph_includes_statement?(g, {EX.S1, EX.P3, EX.O4})
      assert graph_includes_statement?(g, {EX.S2, EX.P2, bnode(:foo)})
      assert graph_includes_statement?(g, {EX.S3, EX.P3, EX.O3})
    end
  end


  describe "delete" do
    setup do
      {:ok,
        graph1: Graph.new({EX.S, EX.p, EX.O}),
        graph2: Graph.new(EX.Graph, {EX.S, EX.p, [EX.O1, EX.O2]}),
        graph3: Graph.new([
          {EX.S1, EX.p1, [EX.O1, EX.O2]},
          {EX.S2, EX.p2, EX.O3},
          {EX.S3, EX.p3, [~B<foo>, ~L"bar"]},
        ])
      }
    end

    test "a single statement as a triple",
          %{graph1: graph1, graph2: graph2} do
      assert Graph.delete(Graph.new, {EX.S, EX.p, EX.O}) == Graph.new
      assert Graph.delete(graph1, {EX.S, EX.p, EX.O}) == Graph.new
      assert Graph.delete(graph2, {EX.S, EX.p, EX.O1}) ==
              Graph.new(EX.Graph, {EX.S, EX.p, EX.O2})
      assert Graph.delete(graph2, {EX.S, EX.p, EX.O1}) ==
              Graph.new(EX.Graph, {EX.S, EX.p, EX.O2})
    end

    test "multiple statements with a triple with multiple objects",
          %{graph1: graph1, graph2: graph2} do
      assert Graph.delete(Graph.new, {EX.S, EX.p, [EX.O1, EX.O2]}) == Graph.new
      assert Graph.delete(graph1, {EX.S, EX.p, [EX.O, EX.O2]}) == Graph.new
      assert Graph.delete(graph2, {EX.S, EX.p, [EX.O1, EX.O2]}) == Graph.new(EX.Graph)
    end

    test "multiple statements with a list of triples",
          %{graph1: graph1, graph2: graph2, graph3: graph3} do
      assert Graph.delete(graph1, [{EX.S, EX.p, EX.O},
                                   {EX.S, EX.p, EX.O2}]) == Graph.new
      assert Graph.delete(graph2, [{EX.S, EX.p, EX.O1},
                                   {EX.S, EX.p, EX.O2}]) == Graph.new(EX.Graph)
      assert Graph.delete(graph3, [
              {EX.S1, EX.p1, [EX.O1, EX.O2]},
              {EX.S2, EX.p2, EX.O3},
              {EX.S3, EX.p3, ~B<foo>}]) == Graph.new({EX.S3, EX.p3, ~L"bar"})
    end

    test "multiple statements with a Description",
          %{graph1: graph1, graph2: graph2, graph3: graph3} do
      assert Graph.delete(graph1, Description.new(EX.S,
                [{EX.p, EX.O}, {EX.p2, EX.O2}])) == Graph.new
      assert Graph.delete(graph2, Description.new(EX.S, EX.p, [EX.O1, EX.O2])) ==
              Graph.new(EX.Graph)
      assert Graph.delete(graph3, Description.new(EX.S3, EX.p3, ~B<foo>)) ==
               Graph.new([
                         {EX.S1, EX.p1, [EX.O1, EX.O2]},
                         {EX.S2, EX.p2, EX.O3},
                         {EX.S3, EX.p3, [~L"bar"]},
                       ])
    end

    test "multiple statements with a Graph",
          %{graph1: graph1, graph2: graph2, graph3: graph3} do
      assert Graph.delete(graph1, graph2) == graph1
      assert Graph.delete(graph1, graph1) == Graph.new
      assert Graph.delete(graph2, Graph.new(EX.Graph, {EX.S, EX.p, [EX.O1, EX.O3]})) ==
              Graph.new(EX.Graph, {EX.S, EX.p, EX.O2})
      assert Graph.delete(graph3, Graph.new([
                {EX.S1, EX.p1, [EX.O1, EX.O2]},
                {EX.S2, EX.p2, EX.O3},
                {EX.S3, EX.p3, ~B<foo>},
              ])) == Graph.new({EX.S3, EX.p3, ~L"bar"})
    end

  end


  describe "delete_subjects" do
    setup do
      {:ok,
        graph1: Graph.new(EX.Graph, {EX.S, EX.p, [EX.O1, EX.O2]}),
        graph2: Graph.new([
          {EX.S1, EX.p1, [EX.O1, EX.O2]},
          {EX.S2, EX.p2, EX.O3},
          {EX.S3, EX.p3, [~B<foo>, ~L"bar"]},
        ])
      }
    end

    test "a single subject", %{graph1: graph1} do
      assert Graph.delete_subjects(graph1, EX.Other) == graph1
      assert Graph.delete_subjects(graph1, EX.S) == Graph.new(EX.Graph)
    end

    test "a list of subjects", %{graph1: graph1, graph2: graph2}  do
      assert Graph.delete_subjects(graph1, [EX.S, EX.Other]) == Graph.new(EX.Graph)
      assert Graph.delete_subjects(graph2, [EX.S1, EX.S2, EX.S3]) == Graph.new
    end
  end


  test "pop" do
    assert Graph.pop(Graph.new) == {nil, Graph.new}

    {triple, graph} = Graph.new({EX.S, EX.p, EX.O}) |> Graph.pop
    assert {iri(EX.S), iri(EX.p), iri(EX.O)} == triple
    assert Enum.count(graph.descriptions) == 0

    {{subject, predicate, _}, graph} =
      Graph.new([{EX.S, EX.p, EX.O1}, {EX.S, EX.p, EX.O2}])
      |> Graph.pop
    assert {subject, predicate} == {iri(EX.S), iri(EX.p)}
    assert Enum.count(graph.descriptions) == 1

    {{subject, _, _}, graph} =
      Graph.new([{EX.S, EX.p1, EX.O1}, {EX.S, EX.p2, EX.O2}])
      |> Graph.pop
    assert subject == iri(EX.S)
    assert Enum.count(graph.descriptions) == 1
  end

  describe "Enumerable protocol" do
    test "Enum.count" do
      assert Enum.count(Graph.new EX.foo) == 0
      assert Enum.count(Graph.new {EX.S, EX.p, EX.O}) == 1
      assert Enum.count(Graph.new [{EX.S, EX.p, EX.O1}, {EX.S, EX.p, EX.O2}]) == 2

      g = Graph.add(graph(), [
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
        {EX.Subject3, EX.predicate3, EX.Object3}
      ])
      assert Enum.count(g) == 3
    end

    test "Enum.member?" do
      refute Enum.member?(Graph.new, {iri(EX.S), EX.p, iri(EX.O)})
      assert Enum.member?(Graph.new({EX.S, EX.p, EX.O}), {EX.S, EX.p, EX.O})

      g = Graph.add(graph(), [
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
        {EX.Subject3, EX.predicate3, EX.Object3}
      ])
      assert Enum.member?(g, {EX.Subject1, EX.predicate1, EX.Object1})
      assert Enum.member?(g, {EX.Subject1, EX.predicate2, EX.Object2})
      assert Enum.member?(g, {EX.Subject3, EX.predicate3, EX.Object3})
    end

    test "Enum.reduce" do
      g = Graph.add(graph(), [
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
        {EX.Subject3, EX.predicate3, EX.Object3}
      ])

      assert g == Enum.reduce(g, graph(),
        fn(triple, acc) -> acc |> Graph.add(triple) end)
    end
  end

  describe "Collectable protocol" do
    test "with a list of triples" do
      triples = [
          {EX.Subject, EX.predicate1, EX.Object1},
          {EX.Subject, EX.predicate2, EX.Object2}
        ]
      assert Enum.into(triples, Graph.new()) == Graph.new(triples)
    end

    test "with a list of lists" do
      lists = [
          [EX.Subject, EX.predicate1, EX.Object1],
          [EX.Subject, EX.predicate2, EX.Object2]
        ]
      assert Enum.into(lists, Graph.new()) ==
              Graph.new(Enum.map(lists, &List.to_tuple/1))
    end
  end

  describe "Access behaviour" do
    test "access with the [] operator" do
      assert Graph.new[EX.Subject] == nil
      assert Graph.new({EX.S, EX.p, EX.O})[EX.S] ==
              Description.new({EX.S, EX.p, EX.O})
    end
  end

end
