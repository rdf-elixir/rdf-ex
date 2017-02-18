defmodule RDF.GraphTest do
  use RDF.Test.Case

  doctest RDF.Graph


  describe "construction" do
    test "creating an empty unnamed graph" do
      assert unnamed_graph?(unnamed_graph())
    end

    test "creating an empty graph with a proper graph name" do
      refute unnamed_graph?(named_graph())
      assert named_graph?(named_graph())
    end

    test "creating an empty graph with a convertible graph name" do
      assert named_graph("http://example.com/graph/GraphName")
             |> named_graph?(uri("http://example.com/graph/GraphName"))
      assert named_graph(EX.Foo) |> named_graph?(uri(EX.Foo))
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
      assert named_graph?(g, uri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})

      g = Graph.new(EX.GraphName, EX.Subject, EX.predicate, EX.Object)
      assert named_graph?(g, uri(EX.GraphName))
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
      assert named_graph?(g, uri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate1, EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate2, EX.Object2})

      g = Graph.new(EX.GraphName, EX.Subject, EX.predicate, [EX.Object1, EX.Object2])
      assert named_graph?(g, uri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object2})
    end

    test "creating a named graph with an initial description" do
      g = Graph.new(EX.GraphName, Description.new({EX.Subject, EX.predicate, EX.Object}))
      assert named_graph?(g, uri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating an unnamed graph with an initial description" do
      g = Graph.new(Description.new({EX.Subject, EX.predicate, EX.Object}))
      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})
    end
  end

  describe "adding triples" do
    test "a proper triple" do
      assert Graph.add(graph(), uri(EX.Subject), EX.predicate, uri(EX.Object))
        |> graph_includes_statement?({EX.Subject, EX.predicate, EX.Object})
      assert Graph.add(graph(), {uri(EX.Subject), EX.predicate, uri(EX.Object)})
        |> graph_includes_statement?({EX.Subject, EX.predicate, EX.Object})
    end

    test "a convertible triple" do
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

    test "non-convertible Triple elements are causing an error" do
      assert_raise RDF.InvalidURIError, fn ->
        Graph.add(graph(), {"not a URI", EX.predicate, uri(EX.Object)})
      end
      assert_raise RDF.InvalidLiteralError, fn ->
        Graph.add(graph(), {EX.Subject, EX.prop, self()})
      end
    end
  end

  describe "putting triples" do
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

    @tag skip: "TODO: Requires Graph.put with a list to differentiate a list of statements and a list of Descriptions. Do we want to support mixed lists also?"
    test "a list of Descriptions" do
      g = Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}])
        |> RDF.Graph.put([
            Description.new(EX.S1, [{EX.P2, EX.O3}, {EX.P2, bnode(:foo)}]),
            Description.new(EX.S2, [{EX.P2, EX.O3}, {EX.P2, EX.O4}])
           ])

        assert Graph.triple_count(g) == 5
        assert graph_includes_statement?(g, {EX.S1, EX.P1, EX.O1})
        assert graph_includes_statement?(g, {EX.S1, EX.P2, EX.O3})
        assert graph_includes_statement?(g, {EX.S1, EX.P2, bnode(:foo)})
        assert graph_includes_statement?(g, {EX.S2, EX.P2, EX.O3})
        assert graph_includes_statement?(g, {EX.S2, EX.P2, EX.O4})
    end
  end

  test "pop a triple" do
    assert Graph.pop(Graph.new) == {nil, Graph.new}

    {triple, graph} = Graph.new({EX.S, EX.p, EX.O}) |> Graph.pop
    assert {uri(EX.S), uri(EX.p), uri(EX.O)} == triple
    assert Enum.count(graph.descriptions) == 0

    {{subject, predicate, _}, graph} =
      Graph.new([{EX.S, EX.p, EX.O1}, {EX.S, EX.p, EX.O2}])
      |> Graph.pop
    assert {subject, predicate} == {uri(EX.S), uri(EX.p)}
    assert Enum.count(graph.descriptions) == 1

    {{subject, _, _}, graph} =
      Graph.new([{EX.S, EX.p1, EX.O1}, {EX.S, EX.p2, EX.O2}])
      |> Graph.pop
    assert subject == uri(EX.S)
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
      refute Enum.member?(Graph.new, {uri(EX.S), EX.p, uri(EX.O)})
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

  describe "Access behaviour" do
    test "access with the [] operator" do
      assert Graph.new[EX.Subject] == nil
      assert Graph.new({EX.S, EX.p, EX.O})[EX.S] ==
              Description.new({EX.S, EX.p, EX.O})
    end
  end

end
