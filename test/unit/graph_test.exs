defmodule RDF.GraphTest do
  use RDF.Test.Case

  doctest RDF.Graph

  alias RDF.PrefixMap
  alias RDF.NS.{XSD, RDFS}

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
      g = Graph.new({EX.Subject, EX.predicate, EX.Object}, name: EX.GraphName)
      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})

      g = Graph.new(EX.Subject, EX.predicate, EX.Object, name: EX.GraphName)
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
      g = Graph.new([{EX.Subject, EX.predicate1, EX.Object1},
                     {EX.Subject, EX.predicate2, EX.Object2}],
                    name: EX.GraphName)
      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate1, EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate2, EX.Object2})

      g = Graph.new(EX.Subject, EX.predicate, [EX.Object1, EX.Object2],
                    name: EX.GraphName)
      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object2})
    end

    test "creating a named graph with an initial description" do
      g = Graph.new(Description.new({EX.Subject, EX.predicate, EX.Object}),
                    name: EX.GraphName)
      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating an unnamed graph with an initial description" do
      g = Graph.new(Description.new({EX.Subject, EX.predicate, EX.Object}))
      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating a named graph from another graph" do
      g = Graph.new(Graph.new({EX.Subject, EX.predicate, EX.Object}),
                    name: EX.GraphName)
      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})

      g = Graph.new(Graph.new({EX.Subject, EX.predicate, EX.Object}, name: EX.OtherGraphName),
                    name: EX.GraphName)
      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating an unnamed graph from another graph" do
      g = Graph.new(Graph.new({EX.Subject, EX.predicate, EX.Object}))
      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})

      g = Graph.new(Graph.new({EX.Subject, EX.predicate, EX.Object}, name: EX.OtherGraphName))
      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate, EX.Object})
    end

    test "with prefixes" do
      assert Graph.new(prefixes: %{ex: EX}) ==
               %Graph{prefixes: PrefixMap.new(ex: EX)}
      assert Graph.new(prefixes: %{ex: EX}, name: EX.graph_name) ==
               %Graph{prefixes: PrefixMap.new(ex: EX), name: EX.graph_name}

      assert Graph.new({EX.Subject, EX.predicate, EX.Object}, prefixes: %{ex: EX}) ==
               %Graph{Graph.new({EX.Subject, EX.predicate, EX.Object}) | prefixes: PrefixMap.new(ex: EX)}
    end

    test "creating a graph from another graph takes the prefixes from the other graph, but overwrites if necessary" do
      prefix_map = PrefixMap.new(ex: EX)
      g = Graph.new(Graph.new(prefixes: prefix_map))
      assert g.prefixes == prefix_map

      g = Graph.new(Graph.new(prefixes: %{ex: XSD, rdfs: RDFS}), prefixes: prefix_map)
      assert g.prefixes == PrefixMap.new(ex: EX, rdfs: RDFS)
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

    test "merges the prefixes of another graph" do
      graph = Graph.new(prefixes: %{xsd: XSD})
              |> Graph.add(Graph.new(prefixes: %{rdfs: RDFS}))
      assert graph.prefixes == PrefixMap.new(xsd: XSD, rdfs: RDFS)
    end

    test "merges the prefixes of another graph and keeps the original mapping in case of conflicts" do
      graph = Graph.new(prefixes: %{ex: EX})
              |> Graph.add(Graph.new(prefixes: %{ex: XSD}))
      assert graph.prefixes == PrefixMap.new(ex: EX)
    end

    test "preserves the name and prefixes on when the data provided is not a graph" do
      graph = Graph.new(name: EX.GraphName, prefixes: %{ex: EX})
              |> Graph.add(EX.Subject, EX.predicate, EX.Object)
      assert graph.name == RDF.iri(EX.GraphName)
      assert graph.prefixes == PrefixMap.new(ex: EX)
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

    test "merges the prefixes of another graph" do
      graph = Graph.new(prefixes: %{xsd: XSD})
              |> Graph.put(Graph.new(prefixes: %{rdfs: RDFS}))
      assert graph.prefixes == PrefixMap.new(xsd: XSD, rdfs: RDFS)
    end

    test "merges the prefixes of another graph and keeps the original mapping in case of conflicts" do
      graph = Graph.new(prefixes: %{ex: EX})
              |> Graph.put(Graph.new(prefixes: %{ex: XSD}))
      assert graph.prefixes == PrefixMap.new(ex: EX)
    end

    test "preserves the name and prefixes" do
      graph = Graph.new(name: EX.GraphName, prefixes: %{ex: EX})
              |> Graph.put(EX.Subject, EX.predicate, EX.Object)
      assert graph.name == RDF.iri(EX.GraphName)
      assert graph.prefixes == PrefixMap.new(ex: EX)
    end
  end


  describe "delete" do
    setup do
      {:ok,
        graph1: Graph.new({EX.S, EX.p, EX.O}),
        graph2: Graph.new({EX.S, EX.p, [EX.O1, EX.O2]}, name: EX.Graph),
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
              Graph.new({EX.S, EX.p, EX.O2}, name: EX.Graph)
      assert Graph.delete(graph2, {EX.S, EX.p, EX.O1}) ==
              Graph.new({EX.S, EX.p, EX.O2}, name: EX.Graph)
    end

    test "multiple statements with a triple with multiple objects",
          %{graph1: graph1, graph2: graph2} do
      assert Graph.delete(Graph.new, {EX.S, EX.p, [EX.O1, EX.O2]}) == Graph.new
      assert Graph.delete(graph1, {EX.S, EX.p, [EX.O, EX.O2]}) == Graph.new
      assert Graph.delete(graph2, {EX.S, EX.p, [EX.O1, EX.O2]}) == Graph.new(name: EX.Graph)
    end

    test "multiple statements with a list of triples",
          %{graph1: graph1, graph2: graph2, graph3: graph3} do
      assert Graph.delete(graph1, [{EX.S, EX.p, EX.O},
                                   {EX.S, EX.p, EX.O2}]) == Graph.new
      assert Graph.delete(graph2, [{EX.S, EX.p, EX.O1},
                                   {EX.S, EX.p, EX.O2}]) == Graph.new(name: EX.Graph)
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
              Graph.new(name: EX.Graph)
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
      assert Graph.delete(graph2, Graph.new({EX.S, EX.p, [EX.O1, EX.O3]},
                          name: EX.Graph)) ==
              Graph.new({EX.S, EX.p, EX.O2}, name: EX.Graph)
      assert Graph.delete(graph3, Graph.new([
                {EX.S1, EX.p1, [EX.O1, EX.O2]},
                {EX.S2, EX.p2, EX.O3},
                {EX.S3, EX.p3, ~B<foo>},
              ])) == Graph.new({EX.S3, EX.p3, ~L"bar"})
    end

    test "preserves the name and prefixes" do
      graph = Graph.new(EX.Subject, EX.predicate, EX.Object, name: EX.GraphName, prefixes: %{ex: EX})
              |> Graph.delete(EX.Subject, EX.predicate, EX.Object)
      assert graph.name == RDF.iri(EX.GraphName)
      assert graph.prefixes == PrefixMap.new(ex: EX)
    end
  end


  describe "delete_subjects" do
    setup do
      {:ok,
        graph1: Graph.new({EX.S, EX.p, [EX.O1, EX.O2]}, name: EX.Graph),
        graph2: Graph.new([
          {EX.S1, EX.p1, [EX.O1, EX.O2]},
          {EX.S2, EX.p2, EX.O3},
          {EX.S3, EX.p3, [~B<foo>, ~L"bar"]},
        ])
      }
    end

    test "a single subject", %{graph1: graph1} do
      assert Graph.delete_subjects(graph1, EX.Other) == graph1
      assert Graph.delete_subjects(graph1, EX.S) == Graph.new(name: EX.Graph)
    end

    test "a list of subjects", %{graph1: graph1, graph2: graph2}  do
      assert Graph.delete_subjects(graph1, [EX.S, EX.Other]) == Graph.new(name: EX.Graph)
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


  test "values/1" do
    assert Graph.new() |> Graph.values() == %{}
    assert Graph.new([{EX.s1, EX.p, EX.o1}, {EX.s2, EX.p, EX.o2}])
           |> Graph.values() ==
             %{
               RDF.Term.value(EX.s1) => %{RDF.Term.value(EX.p) => [RDF.Term.value(EX.o1)]},
               RDF.Term.value(EX.s2) => %{RDF.Term.value(EX.p) => [RDF.Term.value(EX.o2)]},
             }
  end

  test "values/2" do
    mapping = fn
      {:predicate, predicate} ->
        predicate |> to_string() |> String.split("/") |> List.last() |> String.to_atom()
      {_, term} ->
        RDF.Term.value(term)
    end

    assert Graph.new() |> Graph.values(mapping) == %{}
    assert Graph.new([{EX.s1, EX.p, EX.o1}, {EX.s2, EX.p, EX.o2}])
           |> Graph.values(mapping) ==
             %{
               RDF.Term.value(EX.s1) => %{p: [RDF.Term.value(EX.o1)]},
               RDF.Term.value(EX.s2) => %{p: [RDF.Term.value(EX.o2)]},
             }
  end

  describe "add_prefixes/2" do
    test "when prefixes already exist" do
      graph = Graph.new(prefixes: %{xsd: XSD}) |> Graph.add_prefixes(ex: EX)
      assert graph.prefixes == PrefixMap.new(xsd: XSD, ex: EX)
    end

    test "when prefixes are not defined yet" do
      graph = Graph.new() |> Graph.add_prefixes(ex: EX)
      assert graph.prefixes == PrefixMap.new(ex: EX)
    end

    test "when prefixes have conflicting mappings, the new mapping is used" do
      graph = Graph.new(prefixes: %{ex: EX}) |> Graph.add_prefixes(ex: XSD)
      assert graph.prefixes == PrefixMap.new(ex: XSD)
    end

    test "when prefixes have conflicting mappings and a conflict resolver function is provided" do
      graph = Graph.new(prefixes: %{ex: EX}) |> Graph.add_prefixes([ex: XSD], fn _, ns, _ -> ns end)
      assert graph.prefixes == PrefixMap.new(ex: EX)
    end
  end

  describe "delete_prefixes/2" do
    test "when given a single prefix" do
      graph = Graph.new(prefixes: %{ex: EX}) |> Graph.delete_prefixes(:ex)
      assert graph.prefixes == PrefixMap.new()
    end

    test "when given a list of prefixes" do
      graph = Graph.new(prefixes: %{ex1: EX, ex2: EX}) |> Graph.delete_prefixes([:ex1, :ex2, :ex3])
      assert graph.prefixes == PrefixMap.new()
    end

    test "when prefixes are not defined yet" do
      graph = Graph.new() |> Graph.delete_prefixes(:ex)
      assert graph.prefixes == nil
    end
  end

  test "clear_prefixes/1" do
    assert Graph.clear_prefixes(Graph.new(prefixes: %{ex: EX})) == Graph.new
  end

  describe "Enumerable protocol" do
    test "Enum.count" do
      assert Enum.count(Graph.new(name: EX.foo)) == 0
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
