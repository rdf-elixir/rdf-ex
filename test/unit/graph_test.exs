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
      g = Graph.new({EX.Subject, EX.predicate(), EX.Object})
      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate(), EX.Object})
    end

    test "creating a named graph with an initial triple" do
      g = Graph.new({EX.Subject, EX.predicate(), EX.Object}, name: EX.GraphName)
      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate(), EX.Object})
    end

    test "creating an unnamed graph with a list of initial triples" do
      g =
        Graph.new([
          {EX.Subject1, EX.predicate1(), EX.Object1},
          {EX.Subject2, EX.predicate2(), EX.Object2}
        ])

      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject2, EX.predicate2(), EX.Object2})

      g = Graph.new({EX.Subject, EX.predicate(), [EX.Object1, EX.Object2]})
      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate(), EX.Object2})
    end

    test "creating a named graph with a list of initial triples" do
      g =
        Graph.new(
          [{EX.Subject, EX.predicate1(), EX.Object1}, {EX.Subject, EX.predicate2(), EX.Object2}],
          name: EX.GraphName
        )

      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate1(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate2(), EX.Object2})

      g = Graph.new({EX.Subject, EX.predicate(), [EX.Object1, EX.Object2]}, name: EX.GraphName)
      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate(), EX.Object2})
    end

    test "initial triples with an empty object list" do
      assert Graph.new({EX.Subject, EX.predicate(), []}) == Graph.new()
    end

    test "creating a named graph with an initial description" do
      g =
        Description.new(EX.Subject, init: {EX.predicate(), EX.Object})
        |> Graph.new(name: EX.GraphName)

      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate(), EX.Object})
    end

    test "creating an unnamed graph with an initial description" do
      g =
        Description.new(EX.Subject, init: {EX.predicate(), EX.Object})
        |> Graph.new()

      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate(), EX.Object})
    end

    test "creating an unnamed graph with an empty description" do
      g = Graph.new(Description.new(EX.Subject))
      assert empty_graph?(g)
    end

    test "creating a named graph from another graph" do
      g =
        Graph.new({EX.Subject, EX.predicate(), EX.Object})
        |> Graph.new(name: EX.GraphName)

      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate(), EX.Object})

      g =
        Graph.new({EX.Subject, EX.predicate(), EX.Object}, name: EX.OtherGraphName)
        |> Graph.new(name: EX.GraphName)

      assert named_graph?(g, iri(EX.GraphName))
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate(), EX.Object})
    end

    test "creating an unnamed graph from another graph" do
      g = Graph.new(Graph.new({EX.Subject, EX.predicate(), EX.Object}))
      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate(), EX.Object})

      g = Graph.new(Graph.new({EX.Subject, EX.predicate(), EX.Object}, name: EX.OtherGraphName))
      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject, EX.predicate(), EX.Object})
    end

    test "creating an graph from a dataset" do
      g =
        Dataset.new([
          {EX.Subject1, EX.predicate1(), EX.Object1, nil},
          {EX.Subject2, EX.predicate2(), EX.Object2, EX.Graph1},
          {EX.Subject3, EX.predicate3(), EX.Object3, EX.Graph1},
          {EX.Subject3, EX.predicate3(), EX.Object3, EX.Graph2},
          {EX.Subject4, EX.predicate4(), EX.Object4, EX.Graph2}
        ])
        |> Graph.new()

      assert unnamed_graph?(g)
      assert Graph.triple_count(g) == 4
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject2, EX.predicate2(), EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject3, EX.predicate3(), EX.Object3})
      assert graph_includes_statement?(g, {EX.Subject4, EX.predicate4(), EX.Object4})

      g =
        Dataset.new([
          {EX.Subject1, EX.predicate1(), EX.Object1, nil},
          {EX.Subject2, EX.predicate2(), EX.Object2, EX.Graph1},
          {EX.Subject3, EX.predicate3(), EX.Object3, EX.Graph1},
          {EX.Subject3, EX.predicate3(), EX.Object3, EX.Graph2},
          {EX.Subject4, EX.predicate4(), EX.Object4, EX.Graph2}
        ])
        |> Graph.new(name: EX.GraphName)

      assert named_graph?(g, iri(EX.GraphName))
      assert Graph.triple_count(g) == 4
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject2, EX.predicate2(), EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject3, EX.predicate3(), EX.Object3})
      assert graph_includes_statement?(g, {EX.Subject4, EX.predicate4(), EX.Object4})
    end

    test "with a context" do
      g =
        Graph.new(
          [
            {EX.Subject1, p1: EX.Object1},
            %{EX.Subject2 => %{p2: EX.Object2}}
          ],
          context: %{p1: EX.predicate1(), p2: EX.predicate2()}
        )

      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject2, EX.predicate2(), EX.Object2})
    end

    test "with prefixes" do
      assert Graph.new(prefixes: %{ex: EX}) ==
               %Graph{prefixes: PrefixMap.new(ex: EX)}

      assert Graph.new(prefixes: %{ex: EX}, name: EX.graph_name()) ==
               %Graph{prefixes: PrefixMap.new(ex: EX), name: EX.graph_name()}

      assert Graph.new({EX.Subject, EX.predicate(), EX.Object}, prefixes: %{ex: EX}) ==
               %Graph{
                 Graph.new({EX.Subject, EX.predicate(), EX.Object})
                 | prefixes: PrefixMap.new(ex: EX)
               }
    end

    test "with base_iri" do
      assert Graph.new(base_iri: EX.base()) ==
               %Graph{base_iri: EX.base()}

      assert Graph.new(prefixes: %{ex: EX}, base_iri: EX.base()) ==
               %Graph{prefixes: PrefixMap.new(ex: EX), base_iri: EX.base()}

      assert Graph.new({EX.Subject, EX.predicate(), EX.Object}, base_iri: EX.base()) ==
               %Graph{Graph.new({EX.Subject, EX.predicate(), EX.Object}) | base_iri: EX.base()}
    end

    test "creating a graph from another graph takes the prefixes from the other graph, but overwrites if necessary" do
      prefix_map = PrefixMap.new(ex: EX)
      g = Graph.new(Graph.new(prefixes: prefix_map))
      assert g.prefixes == prefix_map

      g = Graph.new(Graph.new(prefixes: %{ex: XSD, rdfs: RDFS}), prefixes: prefix_map)
      assert g.prefixes == PrefixMap.new(ex: EX, rdfs: RDFS)
    end

    @tag skip: "This case is currently not supported, since it's indistinguishable from Keywords"
    test "creating a graph with a list of subject-predications pairs" do
      g =
        Graph.new([
          {EX.S1,
           [
             {EX.P1, EX.O1},
             %{EX.P2 => [EX.O2]}
           ]}
        ])

      assert graph_includes_statement?(g, {EX.S1, EX.P1, EX.O1})
      assert graph_includes_statement?(g, {EX.S1, EX.P2, EX.O2})
    end

    test "with init data" do
      g =
        Graph.new(
          init: [
            {EX.S1,
             [
               {EX.P1, EX.O1},
               %{EX.P2 => [EX.O2]}
             ]}
          ]
        )

      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.S1, EX.P1, EX.O1})
      assert graph_includes_statement?(g, {EX.S1, EX.P2, EX.O2})

      g =
        Graph.new(
          name: EX.Graph,
          init: {EX.S, EX.p(), EX.O}
        )

      assert named_graph?(g, RDF.iri(EX.Graph))
      assert graph_includes_statement?(g, {EX.S, EX.p(), EX.O})
    end

    test "a graph map" do
      g =
        Graph.new(%{
          EX.Subject1 => [{EX.predicate1(), EX.Object1}, {EX.predicate2(), [EX.Object2]}],
          EX.Subject3 => %{EX.predicate3() => EX.Object3}
        })

      assert Graph.triple_count(g) == 3
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate2(), EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject3, EX.predicate3(), EX.Object3})
    end

    test "with an initializer function" do
      g = Graph.new(init: fn -> {EX.S, EX.p(), EX.O} end)
      assert unnamed_graph?(g)
      assert graph_includes_statement?(g, {EX.S, EX.p(), EX.O})
    end
  end

  test "clear/1" do
    opts = [name: EX.Graph, base_iri: EX.base(), prefixes: %{ex: EX.prefix()}]

    assert Graph.new({EX.S, EX.p(), EX.O}, opts)
           |> Graph.clear() == Graph.new(opts)
  end

  test "name/1" do
    assert Graph.name(graph()) == graph().name
  end

  test "change_name/2" do
    assert Graph.change_name(graph(), EX.NewGraph).name == iri(EX.NewGraph)
    assert Graph.change_name(named_graph(), nil).name == nil
  end

  describe "add/3" do
    test "a proper triple" do
      assert Graph.add(graph(), {iri(EX.Subject), EX.predicate(), iri(EX.Object)})
             |> graph_includes_statement?({EX.Subject, EX.predicate(), EX.Object})
    end

    test "a coerced triple" do
      assert Graph.add(
               graph(),
               {"http://example.com/Subject", EX.predicate(), EX.Object}
             )
             |> graph_includes_statement?({EX.Subject, EX.predicate(), EX.Object})
    end

    test "a triple with multiple objects" do
      g = Graph.add(graph(), {EX.Subject1, EX.predicate1(), [EX.Object1, EX.Object2]})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1(), EX.Object2})
    end

    test "a list of triples" do
      g =
        Graph.add(graph(), [
          {EX.Subject1, EX.predicate1(), EX.Object1},
          {EX.Subject1, EX.predicate2(), EX.Object2},
          {EX.Subject3, EX.predicate3(), EX.Object3}
        ])

      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate2(), EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject3, EX.predicate3(), EX.Object3})
    end

    test "a list of subject-predications pairs" do
      g =
        Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}])
        |> Graph.add([
          {EX.S1,
           [
             {EX.P1, EX.O3},
             %{EX.P2 => [EX.O4]}
           ]}
        ])

      assert Graph.triple_count(g) == 4
      assert graph_includes_statement?(g, {EX.S1, EX.P1, EX.O1})
      assert graph_includes_statement?(g, {EX.S1, EX.P1, EX.O3})
      assert graph_includes_statement?(g, {EX.S1, EX.P2, EX.O4})
      assert graph_includes_statement?(g, {EX.S2, EX.P2, EX.O2})
    end

    test "empty object list" do
      assert Graph.add(graph(), {EX.S, EX.P, []}) == graph()
      graph = Graph.new({EX.S, EX.P, EX.O})
      assert Graph.add(graph, {EX.S, EX.P, []}) == graph
    end

    test "a mixed list" do
      g =
        Graph.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}, {EX.S1, EX.p3(), EX.O3}])
        |> Graph.add([
          %{EX.S1 => {EX.p1(), EX.O41}},
          %{
            EX.S1 => %{EX.p1() => EX.O42},
            EX.S2 => %{EX.p2() => EX.O42}
          },
          {EX.S2, {EX.p2(), EX.O43}},
          [{EX.S2, {EX.p2(), EX.O44}}],
          EX.p2(EX.S2, EX.O45)
        ])

      assert Graph.triple_count(g) == 9
      assert graph_includes_statement?(g, {EX.S1, EX.p1(), EX.O1})
      assert graph_includes_statement?(g, {EX.S1, EX.p3(), EX.O3})
      assert graph_includes_statement?(g, {EX.S1, EX.p1(), EX.O41})
      assert graph_includes_statement?(g, {EX.S1, EX.p1(), EX.O42})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O2})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O42})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O43})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O44})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O45})
    end

    test "a graph map" do
      g =
        Graph.add(graph(), %{
          EX.Subject1 => [{EX.predicate1(), EX.Object1}, {EX.predicate2(), [EX.Object2]}],
          EX.Subject3 => %{EX.predicate3() => EX.Object3}
        })

      assert Graph.triple_count(g) == 3
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate2(), EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject3, EX.predicate3(), EX.Object3})
    end

    test "an empty map" do
      assert Graph.add(graph(), %{}) == graph()
    end

    test "a description" do
      g =
        Graph.add(
          graph(),
          Description.new(EX.Subject1)
          |> Description.add([
            {EX.predicate1(), EX.Object1},
            {EX.predicate2(), EX.Object2}
          ])
        )

      assert Graph.triple_count(g) == 2
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate2(), EX.Object2})

      g = Graph.add(g, Description.new(EX.Subject1, init: {EX.predicate3(), EX.Object3}))

      assert Graph.triple_count(g) == 3
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate2(), EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate3(), EX.Object3})
    end

    test "an empty description is ignored" do
      g = Graph.new() |> Graph.add(Description.new(EX.Subject))
      assert empty_graph?(g)
    end

    test "a list of descriptions" do
      g =
        Graph.add(graph(), [
          Description.new(EX.Subject1, init: {EX.predicate1(), EX.Object1}),
          Description.new(EX.Subject2, init: {EX.predicate2(), EX.Object2}),
          Description.new(EX.Subject1, init: {EX.predicate3(), EX.Object3})
        ])

      assert Graph.triple_count(g) == 3
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject2, EX.predicate2(), EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate3(), EX.Object3})
    end

    test "duplicates are ignored" do
      g = Graph.add(graph(), {EX.Subject, EX.predicate(), EX.Object})
      assert Graph.add(g, {EX.Subject, EX.predicate(), EX.Object}) == g
    end

    test "a graph" do
      g =
        Graph.add(
          graph(),
          Graph.new([
            {EX.Subject1, EX.predicate1(), EX.Object1},
            {EX.Subject2, EX.predicate2(), EX.Object2},
            {EX.Subject3, EX.predicate3(), EX.Object3}
          ])
        )

      assert Graph.triple_count(g) == 3
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject2, EX.predicate2(), EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject3, EX.predicate3(), EX.Object3})

      g =
        Graph.add(
          g,
          Graph.new([
            {EX.Subject1, EX.predicate1(), EX.Object2},
            {EX.Subject2, EX.predicate4(), EX.Object4}
          ])
        )

      assert Graph.triple_count(g) == 5
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1(), EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject2, EX.predicate2(), EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject2, EX.predicate4(), EX.Object4})
      assert graph_includes_statement?(g, {EX.Subject3, EX.predicate3(), EX.Object3})
    end

    test "a dataset" do
      g =
        Graph.add(
          graph(),
          Dataset.new([
            {EX.Subject1, EX.predicate1(), EX.Object1, nil},
            {EX.Subject2, EX.predicate2(), EX.Object2, EX.Graph1},
            {EX.Subject3, EX.predicate3(), EX.Object3, EX.Graph1},
            {EX.Subject3, EX.predicate3(), EX.Object3, EX.Graph2},
            {EX.Subject4, EX.predicate4(), EX.Object4, EX.Graph2}
          ])
        )

      assert Graph.triple_count(g) == 4
      assert graph_includes_statement?(g, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert graph_includes_statement?(g, {EX.Subject2, EX.predicate2(), EX.Object2})
      assert graph_includes_statement?(g, {EX.Subject3, EX.predicate3(), EX.Object3})
      assert graph_includes_statement?(g, {EX.Subject4, EX.predicate4(), EX.Object4})
    end

    test "merges the prefixes of another graph" do
      graph =
        Graph.new(prefixes: %{xsd: XSD})
        |> Graph.add(Graph.new(prefixes: %{rdfs: RDFS}))

      assert graph.prefixes == PrefixMap.new(xsd: XSD, rdfs: RDFS)
    end

    test "merges the prefixes of another graph and keeps the original mapping in case of conflicts" do
      graph =
        Graph.new(prefixes: %{ex: EX})
        |> Graph.add(Graph.new(prefixes: %{ex: XSD}))

      assert graph.prefixes == PrefixMap.new(ex: EX)
    end

    test "preserves the base_iri" do
      graph =
        Graph.new()
        |> Graph.add(Graph.new({EX.Subject, EX.predicate(), EX.Object}, base_iri: EX.base()))

      assert graph.base_iri == Graph.new().base_iri
    end

    test "preserves the name and prefixes when the data provided is not a graph" do
      graph =
        Graph.new(name: EX.GraphName, prefixes: %{ex: EX})
        |> Graph.add({EX.Subject, EX.predicate(), EX.Object})

      assert graph.name == RDF.iri(EX.GraphName)
      assert graph.prefixes == PrefixMap.new(ex: EX)
    end

    test "with a context" do
      context =
        PropertyMap.new(
          p1: EX.p1(),
          p2: EX.p2()
        )

      assert Graph.add(graph(), {EX.Subject, :p, 42}, context: [p: EX.predicate()])
             |> graph_includes_statement?({RDF.iri(EX.Subject), EX.predicate(), literal(42)})

      assert Graph.add(graph(), {EX.Subject, :p, 42, EX.Graph}, context: %{p: EX.predicate()})
             |> graph_includes_statement?({RDF.iri(EX.Subject), EX.predicate(), literal(42)})

      g =
        Graph.add(
          graph(),
          [
            {EX.S1, :p1, EX.O1},
            {EX.S2, :p2, [EX.O21, EX.O22]}
          ],
          context: context
        )

      assert Graph.triple_count(g) == 3
      assert graph_includes_statement?(g, {EX.S1, EX.p1(), EX.O1})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O21})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O22})

      g =
        Graph.add(
          graph(),
          [
            {EX.S1,
             [
               {:p1, EX.O1},
               %{p2: [EX.O2]}
             ]}
          ],
          context: context
        )

      assert Graph.triple_count(g) == 2
      assert graph_includes_statement?(g, {EX.S1, EX.p1(), EX.O1})
      assert graph_includes_statement?(g, {EX.S1, EX.p2(), EX.O2})

      g =
        Graph.add(
          graph(),
          [
            %{EX.S1 => {:p1, EX.O1}},
            %{
              EX.S1 => %{p1: EX.O11},
              EX.S2 => %{p1: EX.O2}
            },
            {EX.S2, {:p2, EX.O2}},
            [{EX.S2, {:p2, EX.O21}}],
            EX.p2(EX.S2, EX.O22)
          ],
          context: context
        )

      assert Graph.triple_count(g) == 6
      assert graph_includes_statement?(g, {EX.S1, EX.p1(), EX.O1})
      assert graph_includes_statement?(g, {EX.S1, EX.p1(), EX.O11})

      assert graph_includes_statement?(g, {EX.S2, EX.p1(), EX.O2})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O2})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O21})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O22})
    end

    test "non-coercible Triple elements are causing an error" do
      assert_raise RDF.IRI.InvalidError, fn ->
        Graph.add(graph(), {"not a IRI", EX.predicate(), iri(EX.Object)})
      end

      assert_raise RDF.Literal.InvalidError, fn ->
        Graph.add(graph(), {EX.Subject, EX.prop(), self()})
      end
    end

    test "structs are causing an error" do
      assert_raise FunctionClauseError, fn ->
        Graph.add(graph(), Date.utc_today())
      end

      assert_raise FunctionClauseError, fn ->
        Graph.add(graph(), RDF.bnode())
      end
    end
  end

  describe "put/3" do
    test "a list of triples" do
      g =
        Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}, {EX.S3, EX.P3, EX.O3}])
        |> Graph.put([
          {EX.S1, EX.P2, EX.O3},
          {EX.S1, EX.P2, bnode(:foo)},
          {EX.S2, EX.P3, EX.O3}
        ])

      assert Graph.triple_count(g) == 4
      assert graph_includes_statement?(g, {EX.S1, EX.P2, EX.O3})
      assert graph_includes_statement?(g, {EX.S1, EX.P2, bnode(:foo)})
      assert graph_includes_statement?(g, {EX.S2, EX.P3, EX.O3})
      assert graph_includes_statement?(g, {EX.S3, EX.P3, EX.O3})
    end

    test "quads" do
      g =
        Graph.new([{EX.S1, EX.P1, EX.O}, {EX.S2, EX.P2, EX.O}])
        |> Graph.put([
          {EX.S1, EX.P3, bnode(:foo), EX.Graph1},
          {EX.S2, EX.P3, EX.O1, EX.Graph2},
          {EX.S2, EX.P3, EX.O2, nil},
          {EX.S2, EX.P3, EX.O3}
        ])

      assert Graph.triple_count(g) == 4
      assert graph_includes_statement?(g, {EX.S1, EX.P3, bnode(:foo)})
      assert graph_includes_statement?(g, {EX.S2, EX.P3, EX.O1})
      assert graph_includes_statement?(g, {EX.S2, EX.P3, EX.O2})
      assert graph_includes_statement?(g, {EX.S2, EX.P3, EX.O3})
    end

    test "a list of subject-predications pairs" do
      g =
        Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}])
        |> Graph.put([
          {EX.S1,
           [
             {EX.P3, EX.O3},
             %{EX.P4 => [EX.O4]}
           ]}
        ])

      assert Graph.triple_count(g) == 3
      assert graph_includes_statement?(g, {EX.S1, EX.P3, EX.O3})
      assert graph_includes_statement?(g, {EX.S1, EX.P4, EX.O4})
      assert graph_includes_statement?(g, {EX.S2, EX.P2, EX.O2})
    end

    test "a mixed list" do
      g =
        Graph.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}, {EX.S1, EX.p3(), EX.O3}])
        |> Graph.put([
          %{EX.S1 => {EX.p1(), EX.O41}},
          %{
            EX.S1 => %{EX.p1() => EX.O42},
            EX.S2 => %{EX.p3() => EX.O42}
          },
          {EX.S2, {EX.p3(), EX.O43}},
          [{EX.S2, {EX.p3(), EX.O44}}],
          EX.p2(EX.S3, EX.O45)
        ])

      assert Graph.triple_count(g) == 6
      assert graph_includes_statement?(g, {EX.S1, EX.p1(), EX.O41})
      assert graph_includes_statement?(g, {EX.S1, EX.p1(), EX.O42})
      assert graph_includes_statement?(g, {EX.S2, EX.p3(), EX.O42})
      assert graph_includes_statement?(g, {EX.S2, EX.p3(), EX.O43})
      assert graph_includes_statement?(g, {EX.S2, EX.p3(), EX.O44})
      assert graph_includes_statement?(g, {EX.S3, EX.p2(), EX.O45})
    end

    test "a map" do
      g =
        Graph.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}])
        |> Graph.put(%{
          EX.S1 => [{EX.p1(), EX.O2}],
          EX.S2 => %{EX.p1() => EX.O2},
          EX.S3 => %{EX.p3() => EX.O3}
        })

      assert Graph.triple_count(g) == 3
      assert graph_includes_statement?(g, {EX.S1, EX.p1(), EX.O2})
      assert graph_includes_statement?(g, {EX.S2, EX.p1(), EX.O2})
      assert graph_includes_statement?(g, {EX.S3, EX.p3(), EX.O3})
    end

    test "a description" do
      g =
        Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}, {EX.S1, EX.P3, EX.O3}])
        |> Graph.put(
          Description.new(EX.S1)
          |> Description.add([{EX.P3, EX.O4}, {EX.P2, bnode(:foo)}])
        )

      assert Graph.triple_count(g) == 3
      assert graph_includes_statement?(g, {EX.S1, EX.P3, EX.O4})
      assert graph_includes_statement?(g, {EX.S1, EX.P2, bnode(:foo)})
      assert graph_includes_statement?(g, {EX.S2, EX.P2, EX.O2})
    end

    test "an empty description is ignored" do
      g = Graph.new() |> Graph.put(Description.new(EX.Subject))
      assert empty_graph?(g)
    end

    test "a list of descriptions" do
      g =
        Graph.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}, {EX.S3, EX.p3(), EX.O3}])
        |> Graph.put([
          EX.p2(EX.S1, EX.O41),
          EX.p2(EX.S2, EX.O42),
          EX.p2(EX.S2, EX.O43)
        ])

      assert Graph.triple_count(g) == 4
      assert graph_includes_statement?(g, {EX.S3, EX.p3(), EX.O3})
      assert graph_includes_statement?(g, {EX.S1, EX.p2(), EX.O41})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O42})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O43})
    end

    test "a graph" do
      g =
        Graph.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S2, EX.P2, EX.O2}
        ])
        |> Graph.put(
          Graph.new([
            {EX.S1, EX.P12, EX.O12},
            {EX.S3, EX.P3, EX.O3}
          ])
        )

      assert Graph.triple_count(g) == 3
      assert graph_includes_statement?(g, {EX.S1, EX.P12, EX.O12})
      assert graph_includes_statement?(g, {EX.S2, EX.P2, EX.O2})
      assert graph_includes_statement?(g, {EX.S3, EX.P3, EX.O3})
    end

    test "merges the prefixes of another graph" do
      graph =
        Graph.new(prefixes: %{xsd: XSD})
        |> Graph.put(Graph.new(prefixes: %{rdfs: RDFS}))

      assert graph.prefixes == PrefixMap.new(xsd: XSD, rdfs: RDFS)
    end

    test "merges the prefixes of another graph and keeps the original mapping in case of conflicts" do
      graph =
        Graph.new(prefixes: %{ex: EX})
        |> Graph.put(Graph.new(prefixes: %{ex: XSD}))

      assert graph.prefixes == PrefixMap.new(ex: EX)
    end

    test "preserves the name, base_iri and prefixes" do
      graph =
        Graph.new(name: EX.GraphName, prefixes: %{ex: EX}, base_iri: EX.base())
        |> Graph.put({EX.Subject, EX.predicate(), EX.Object})

      assert graph.name == RDF.iri(EX.GraphName)
      assert graph.prefixes == PrefixMap.new(ex: EX)
      assert graph.base_iri == EX.base()
    end

    test "with a context" do
      g =
        Graph.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}])
        |> Graph.put(
          %{
            EX.S1 => [p1: EX.O2],
            EX.S2 => %{p1: EX.O2},
            EX.S3 => %{p3: EX.O3}
          },
          context: [p1: EX.p1(), p3: EX.p3()]
        )

      assert Graph.triple_count(g) == 3
      assert graph_includes_statement?(g, {EX.S1, EX.p1(), EX.O2})
      assert graph_includes_statement?(g, {EX.S2, EX.p1(), EX.O2})
      assert graph_includes_statement?(g, {EX.S3, EX.p3(), EX.O3})
    end

    test "RDF.Datasets are causing an error" do
      assert_raise ArgumentError, fn ->
        Graph.put(graph(), RDF.dataset())
      end
    end

    test "structs are causing an error" do
      assert_raise FunctionClauseError, fn ->
        Graph.put(graph(), Date.utc_today())
      end

      assert_raise FunctionClauseError, fn ->
        Graph.put(graph(), RDF.bnode())
      end
    end
  end

  describe "put_properties/3" do
    test "a list of triples" do
      g =
        Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}])
        |> Graph.put_properties([
          {EX.S1, EX.P2, EX.O3},
          {EX.S1, EX.P2, bnode(:foo)},
          {EX.S2, EX.P2, EX.O3},
          {EX.S2, EX.P2, EX.O4}
        ])

      assert Graph.triple_count(g) == 5
      assert graph_includes_statement?(g, {EX.S1, EX.P1, EX.O1})
      assert graph_includes_statement?(g, {EX.S1, EX.P2, EX.O3})
      assert graph_includes_statement?(g, {EX.S1, EX.P2, bnode(:foo)})
      assert graph_includes_statement?(g, {EX.S2, EX.P2, EX.O3})
      assert graph_includes_statement?(g, {EX.S2, EX.P2, EX.O4})
    end

    test "quads" do
      g =
        Graph.new([{EX.S1, EX.P1, EX.O}, {EX.S2, EX.P2, EX.O}])
        |> Graph.put_properties([
          {EX.S2, EX.P2, bnode(:foo), EX.Graph1},
          {EX.S2, EX.P2, EX.O1, EX.Graph2},
          {EX.S2, EX.P2, EX.O2, nil},
          {EX.S2, EX.P2, EX.O3}
        ])

      assert Graph.triple_count(g) == 5
      assert graph_includes_statement?(g, {EX.S1, EX.P1, EX.O})
      assert graph_includes_statement?(g, {EX.S2, EX.P2, bnode(:foo)})
      assert graph_includes_statement?(g, {EX.S2, EX.P2, EX.O1})
      assert graph_includes_statement?(g, {EX.S2, EX.P2, EX.O2})
      assert graph_includes_statement?(g, {EX.S2, EX.P2, EX.O3})
    end

    test "a list of subject-predications pairs" do
      g =
        Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}])
        |> Graph.put_properties([
          {EX.S1,
           [
             {EX.P1, EX.O3},
             %{EX.P2 => [EX.O4]}
           ]}
        ])

      assert Graph.triple_count(g) == 3
      assert graph_includes_statement?(g, {EX.S1, EX.P1, EX.O3})
      assert graph_includes_statement?(g, {EX.S1, EX.P2, EX.O4})
      assert graph_includes_statement?(g, {EX.S2, EX.P2, EX.O2})
    end

    test "a mixed list" do
      g =
        Graph.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}, {EX.S1, EX.p3(), EX.O3}])
        |> Graph.put_properties([
          %{EX.S1 => {EX.p1(), EX.O41}},
          %{
            EX.S1 => %{EX.p1() => EX.O42},
            EX.S2 => %{EX.p2() => EX.O42}
          },
          {EX.S2, {EX.p2(), EX.O43}},
          [{EX.S2, {EX.p2(), EX.O44}}],
          EX.p2(EX.S2, EX.O45)
        ])

      assert Graph.triple_count(g) == 7
      assert graph_includes_statement?(g, {EX.S1, EX.p3(), EX.O3})
      assert graph_includes_statement?(g, {EX.S1, EX.p1(), EX.O41})
      assert graph_includes_statement?(g, {EX.S1, EX.p1(), EX.O42})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O42})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O43})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O44})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O45})
    end

    test "a map" do
      g =
        Graph.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}])
        |> Graph.put_properties(%{
          EX.S1 => [{EX.p1(), EX.O2}],
          EX.S2 => %{EX.p1() => EX.O2},
          EX.S3 => %{EX.p3() => EX.O3}
        })

      assert Graph.triple_count(g) == 4
      assert graph_includes_statement?(g, {EX.S1, EX.p1(), EX.O2})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O2})
      assert graph_includes_statement?(g, {EX.S2, EX.p1(), EX.O2})
      assert graph_includes_statement?(g, {EX.S3, EX.p3(), EX.O3})
    end

    test "a description" do
      g =
        Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}, {EX.S1, EX.P3, EX.O3}])
        |> Graph.put_properties(
          Description.new(EX.S1)
          |> Description.add([{EX.P3, EX.O4}, {EX.P2, bnode(:foo)}])
        )

      assert Graph.triple_count(g) == 4
      assert graph_includes_statement?(g, {EX.S1, EX.P1, EX.O1})
      assert graph_includes_statement?(g, {EX.S1, EX.P3, EX.O4})
      assert graph_includes_statement?(g, {EX.S1, EX.P2, bnode(:foo)})
      assert graph_includes_statement?(g, {EX.S2, EX.P2, EX.O2})
    end

    test "an empty description is ignored" do
      g = Graph.new() |> Graph.put_properties(Description.new(EX.Subject))
      assert empty_graph?(g)
    end

    test "a list of descriptions" do
      g =
        Graph.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}, {EX.S1, EX.p3(), EX.O3}])
        |> Graph.put_properties([
          EX.p1(EX.S1, EX.O41),
          EX.p2(EX.S2, EX.O42),
          EX.p2(EX.S2, EX.O43)
        ])

      assert Graph.triple_count(g) == 4
      assert graph_includes_statement?(g, {EX.S1, EX.p3(), EX.O3})
      assert graph_includes_statement?(g, {EX.S1, EX.p1(), EX.O41})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O42})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O43})
    end

    test "a graph" do
      g =
        Graph.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S1, EX.P3, EX.O3},
          {EX.S2, EX.P2, EX.O2}
        ])
        |> Graph.put_properties(
          Graph.new([
            {EX.S1, EX.P3, EX.O4},
            {EX.S2, EX.P2, bnode(:foo)},
            {EX.S3, EX.P3, EX.O3}
          ])
        )

      assert Graph.triple_count(g) == 4
      assert graph_includes_statement?(g, {EX.S1, EX.P1, EX.O1})
      assert graph_includes_statement?(g, {EX.S1, EX.P3, EX.O4})
      assert graph_includes_statement?(g, {EX.S2, EX.P2, bnode(:foo)})
      assert graph_includes_statement?(g, {EX.S3, EX.P3, EX.O3})
    end

    test "merges the prefixes of another graph" do
      graph =
        Graph.new(prefixes: %{xsd: XSD})
        |> Graph.put_properties(Graph.new(prefixes: %{rdfs: RDFS}))

      assert graph.prefixes == PrefixMap.new(xsd: XSD, rdfs: RDFS)
    end

    test "merges the prefixes of another graph and keeps the original mapping in case of conflicts" do
      graph =
        Graph.new(prefixes: %{ex: EX})
        |> Graph.put_properties(Graph.new(prefixes: %{ex: XSD}))

      assert graph.prefixes == PrefixMap.new(ex: EX)
    end

    test "preserves the name, base_iri and prefixes" do
      graph =
        Graph.new(name: EX.GraphName, prefixes: %{ex: EX}, base_iri: EX.base())
        |> Graph.put_properties({EX.Subject, EX.predicate(), EX.Object})

      assert graph.name == RDF.iri(EX.GraphName)
      assert graph.prefixes == PrefixMap.new(ex: EX)
      assert graph.base_iri == EX.base()
    end

    test "with a context" do
      g =
        Graph.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}])
        |> Graph.put_properties(
          %{
            EX.S1 => [p1: EX.O2],
            EX.S2 => %{p1: EX.O2},
            EX.S3 => %{p3: EX.O3}
          },
          context: [p1: EX.p1(), p3: EX.p3()]
        )

      assert Graph.triple_count(g) == 4
      assert graph_includes_statement?(g, {EX.S1, EX.p1(), EX.O2})
      assert graph_includes_statement?(g, {EX.S2, EX.p1(), EX.O2})
      assert graph_includes_statement?(g, {EX.S2, EX.p2(), EX.O2})
      assert graph_includes_statement?(g, {EX.S3, EX.p3(), EX.O3})
    end

    test "RDF.Datasets are causing an error" do
      assert_raise ArgumentError, fn ->
        Graph.put_properties(graph(), RDF.dataset())
      end
    end

    test "structs are causing an error" do
      assert_raise FunctionClauseError, fn ->
        Graph.put_properties(graph(), Date.utc_today())
      end

      assert_raise FunctionClauseError, fn ->
        Graph.put_properties(graph(), RDF.bnode())
      end
    end
  end

  describe "delete/3" do
    setup do
      {:ok,
       graph1: Graph.new({EX.S, EX.p(), EX.O}),
       graph2: Graph.new({EX.S, EX.p(), [EX.O1, EX.O2]}, name: EX.Graph),
       graph3:
         Graph.new([
           {EX.S1, EX.p1(), [EX.O1, EX.O2]},
           {EX.S2, EX.p2(), EX.O3},
           {EX.S3, EX.p3(), [~B<foo>, ~L"bar"]}
         ])}
    end

    test "a triple",
         %{graph1: graph1, graph2: graph2} do
      assert Graph.delete(Graph.new(), {EX.S, EX.p(), EX.O}) == Graph.new()
      assert Graph.delete(graph1, {EX.S, EX.p(), EX.O}) == Graph.new()

      assert Graph.delete(graph2, {EX.S, EX.p(), EX.O1}) ==
               Graph.new({EX.S, EX.p(), EX.O2}, name: EX.Graph)

      assert Graph.delete(graph2, {EX.S, EX.p(), EX.O1}) ==
               Graph.new({EX.S, EX.p(), EX.O2}, name: EX.Graph)
    end

    test "a triple with multiple objects", %{graph1: graph1, graph2: graph2} do
      assert Graph.delete(Graph.new(), {EX.S, EX.p(), [EX.O1, EX.O2]}) == Graph.new()
      assert Graph.delete(graph1, {EX.S, EX.p(), [EX.O, EX.O2]}) == Graph.new()
      assert Graph.delete(graph2, {EX.S, EX.p(), [EX.O1, EX.O2]}) == Graph.new(name: EX.Graph)
    end

    test "a list of triples", %{graph1: graph1, graph2: graph2, graph3: graph3} do
      assert Graph.delete(graph1, [{EX.S, EX.p(), EX.O}, {EX.S, EX.p(), EX.O2}]) == Graph.new()

      assert Graph.delete(graph2, [{EX.S, EX.p(), EX.O1}, {EX.S, EX.p(), EX.O2}]) ==
               Graph.new(name: EX.Graph)

      assert Graph.delete(graph3, [
               {EX.S1, EX.p1(), [EX.O1, EX.O2]},
               {EX.S2, EX.p2(), EX.O3},
               {EX.S3, EX.p3(), ~B<foo>}
             ]) == Graph.new({EX.S3, EX.p3(), ~L"bar"})
    end

    test "a map", %{graph1: graph1, graph2: graph2, graph3: graph3} do
      assert Graph.delete(graph1, %{EX.S => {EX.p(), [EX.O, EX.O2]}}) == Graph.new()

      assert Graph.delete(graph2, %{EX.S => {EX.p(), [EX.O1, EX.O2]}}) ==
               Graph.new(name: EX.Graph)

      assert Graph.delete(
               graph3,
               %{
                 EX.S1 => %{EX.p1() => [EX.O1, EX.O2]},
                 EX.S2 => %{EX.p2() => EX.O3},
                 EX.S3 => %{EX.p3() => ~B<foo>}
               }
             ) == Graph.new({EX.S3, EX.p3(), ~L"bar"})
    end

    test "a description",
         %{graph1: graph1, graph2: graph2, graph3: graph3} do
      assert Graph.delete(
               graph1,
               Description.new(EX.S)
               |> Description.add([{EX.p(), EX.O}, {EX.p2(), EX.O2}])
             ) == Graph.new()

      assert Graph.delete(graph2, Description.new(EX.S, init: {EX.p(), [EX.O1, EX.O2]})) ==
               Graph.new(name: EX.Graph)

      assert Graph.delete(graph3, Description.new(EX.S3, init: {EX.p3(), ~B<foo>})) ==
               Graph.new([
                 {EX.S1, EX.p1(), [EX.O1, EX.O2]},
                 {EX.S2, EX.p2(), EX.O3},
                 {EX.S3, EX.p3(), [~L"bar"]}
               ])
    end

    test "a graph",
         %{graph1: graph1, graph2: graph2, graph3: graph3} do
      assert Graph.delete(graph1, graph2) == graph1
      assert Graph.delete(graph1, graph1) == Graph.new()

      assert Graph.delete(
               graph2,
               Graph.new({EX.S, EX.p(), [EX.O1, EX.O3]}, name: EX.Graph)
             ) ==
               Graph.new({EX.S, EX.p(), EX.O2}, name: EX.Graph)

      assert Graph.delete(
               graph3,
               Graph.new([
                 {EX.S1, EX.p1(), [EX.O1, EX.O2]},
                 {EX.S2, EX.p2(), EX.O3},
                 {EX.S3, EX.p3(), ~B<foo>}
               ])
             ) == Graph.new({EX.S3, EX.p3(), ~L"bar"})
    end

    test "with a context", %{graph2: graph2} do
      assert Graph.delete(
               graph2,
               [
                 %{EX.S => %{p: EX.O1}},
                 %{EX.S => {:p, [EX.O2]}}
               ],
               context: [p: EX.p()]
             ) ==
               Graph.new(name: EX.Graph)
    end

    test "preserves the name and prefixes" do
      graph =
        Graph.new({EX.Subject, EX.predicate(), EX.Object}, name: EX.GraphName, prefixes: %{ex: EX})
        |> Graph.delete({EX.Subject, EX.predicate(), EX.Object})

      assert graph.name == RDF.iri(EX.GraphName)
      assert graph.prefixes == PrefixMap.new(ex: EX)
    end

    test "structs are causing an error" do
      assert_raise FunctionClauseError, fn ->
        Graph.delete(graph(), Date.utc_today())
      end

      assert_raise FunctionClauseError, fn ->
        Graph.delete(graph(), RDF.dataset())
      end
    end
  end

  describe "delete_descriptions/2" do
    setup do
      {:ok,
       graph1: Graph.new({EX.S, EX.p(), [EX.O1, EX.O2]}, name: EX.Graph),
       graph2:
         Graph.new([
           {EX.S1, EX.p1(), [EX.O1, EX.O2]},
           {EX.S2, EX.p2(), EX.O3},
           {EX.S3, EX.p3(), [~B<foo>, ~L"bar"]}
         ])}
    end

    test "a single subject", %{graph1: graph1} do
      assert Graph.delete_descriptions(graph1, EX.Other) == graph1
      assert Graph.delete_descriptions(graph1, EX.S) == Graph.new(name: EX.Graph)
    end

    test "a list of subjects", %{graph1: graph1, graph2: graph2} do
      assert Graph.delete_descriptions(graph1, [EX.S, EX.Other]) == Graph.new(name: EX.Graph)
      assert Graph.delete_descriptions(graph2, [EX.S1, EX.S2, EX.S3]) == Graph.new()
    end
  end

  describe "update/4" do
    test "a description returned from the update function becomes new description of the subject" do
      old_description = Description.new(EX.S2, init: {EX.p2(), EX.O3})
      new_description = Description.new(EX.S2, init: {EX.p(), EX.O})

      assert Graph.new([
               {EX.S1, EX.p1(), [EX.O1, EX.O2]},
               old_description
             ])
             |> Graph.update(EX.S2, fn ^old_description -> new_description end) ==
               Graph.new([
                 {EX.S1, EX.p1(), [EX.O1, EX.O2]},
                 new_description
               ])
    end

    test "a description with another subject returned from the update function becomes new description of the subject" do
      old_description = Description.new(EX.S2, init: {EX.p2(), EX.O3})
      new_description = Description.new(EX.S2, init: {EX.p(), EX.O})

      assert Graph.new([
               {EX.S1, EX.p1(), [EX.O1, EX.O2]},
               old_description
             ])
             |> Graph.update(
               EX.S2,
               fn ^old_description ->
                 Description.new(EX.S3, init: new_description)
               end
             ) ==
               Graph.new([
                 {EX.S1, EX.p1(), [EX.O1, EX.O2]},
                 new_description
               ])
    end

    test "a value returned from the update function becomes new coerced description of the subject" do
      old_description = Description.new(EX.S2, init: {EX.p2(), EX.O3})
      new_description = {EX.p(), [EX.O1, EX.O2]}

      assert Graph.new([
               {EX.S1, EX.p1(), [EX.O1, EX.O2]},
               old_description
             ])
             |> Graph.update(
               EX.S2,
               fn ^old_description -> new_description end
             ) ==
               Graph.new([
                 {EX.S1, EX.p1(), [EX.O1, EX.O2]},
                 Description.new(EX.S2)
                 |> Description.add(new_description)
               ])
    end

    test "returning nil from the update function causes a removal of the description" do
      assert Graph.new({EX.S, EX.p(), EX.O})
             |> Graph.update(EX.S, fn _ -> nil end) ==
               Graph.new()
    end

    test "when the property is not present the initial object value is added for the predicate and the update function not called" do
      fun = fn _ -> raise "should not be called" end

      assert Graph.new()
             |> Graph.update(EX.S, {EX.P, EX.O}, fun) ==
               Graph.new({EX.S, EX.P, EX.O})

      assert Graph.new()
             |> Graph.update(EX.S, fun) ==
               Graph.new()
    end
  end

  test "pop" do
    assert Graph.pop(Graph.new()) == {nil, Graph.new()}

    {triple, graph} = Graph.new({EX.S, EX.p(), EX.O}) |> Graph.pop()
    assert {iri(EX.S), iri(EX.p()), iri(EX.O)} == triple
    assert Enum.count(graph.descriptions) == 0

    {{subject, predicate, _}, graph} =
      Graph.new([{EX.S, EX.p(), EX.O1}, {EX.S, EX.p(), EX.O2}])
      |> Graph.pop()

    assert {subject, predicate} == {iri(EX.S), iri(EX.p())}
    assert Enum.count(graph.descriptions) == 1

    {{subject, _, _}, graph} =
      Graph.new([{EX.S, EX.p1(), EX.O1}, {EX.S, EX.p2(), EX.O2}])
      |> Graph.pop()

    assert subject == iri(EX.S)
    assert Enum.count(graph.descriptions) == 1
  end

  test "statement_count/1" do
    assert Graph.statement_count(graph()) == 0
    assert Graph.statement_count(Graph.new(statement())) == 1
  end

  describe "include?/3" do
    test "valid cases" do
      graph =
        Graph.new([
          {EX.S1, EX.p(), EX.O1},
          {EX.S2, EX.p(), EX.O2}
        ])

      assert Graph.include?(graph, {EX.S1, EX.p(), EX.O1})
      assert Graph.include?(graph, {EX.S1, EX.p(), EX.O1, EX.Graph})

      assert Graph.include?(graph, [{EX.S1, EX.p(), EX.O1}])

      assert Graph.include?(graph, [
               {EX.S1, EX.p(), EX.O1},
               {EX.S2, EX.p(), EX.O2}
             ])

      refute Graph.include?(graph, [
               {EX.S1, EX.p(), EX.O1},
               {EX.S2, EX.p(), EX.O3}
             ])

      assert Graph.include?(graph, EX.S1 |> EX.p(EX.O1))
      assert Graph.include?(graph, Graph.new(EX.S1 |> EX.p(EX.O1)))
      assert Graph.include?(graph, graph)

      assert Graph.include?(
               graph,
               [
                 %{EX.S1 => %{p: EX.O1}},
                 %{EX.S2 => {:p, [EX.O2]}}
               ],
               context: [p: EX.p()]
             )
    end

    test "structs are causing an error" do
      assert_raise FunctionClauseError, fn ->
        Graph.include?(graph(), Date.utc_today())
      end

      assert_raise FunctionClauseError, fn ->
        Graph.include?(graph(), RDF.dataset())
      end
    end
  end

  test "values/1" do
    assert Graph.new() |> Graph.values() == %{}

    assert Graph.new([{EX.s1(), EX.p(), EX.o1()}, {EX.s2(), EX.p(), EX.o2()}])
           |> Graph.values() ==
             %{
               RDF.Term.value(EX.s1()) => %{RDF.Term.value(EX.p()) => [RDF.Term.value(EX.o1())]},
               RDF.Term.value(EX.s2()) => %{RDF.Term.value(EX.p()) => [RDF.Term.value(EX.o2())]}
             }
  end

  test "values/2" do
    expected_result = %{
      RDF.Term.value(EX.s1()) => %{p: [RDF.Term.value(EX.o1())]},
      RDF.Term.value(EX.s2()) => %{p: [RDF.Term.value(EX.o2())]}
    }

    assert Graph.new([{EX.s1(), EX.p(), EX.o1()}, {EX.s2(), EX.p(), EX.o2()}])
           |> Graph.values(context: PropertyMap.new(p: EX.p())) ==
             expected_result

    assert Graph.new([{EX.s1(), EX.p(), EX.o1()}, {EX.s2(), EX.p(), EX.o2()}])
           |> Graph.values(context: [p: EX.p()]) ==
             expected_result
  end

  test "map/2" do
    mapping = fn
      {:predicate, predicate} ->
        predicate |> to_string() |> String.split("/") |> List.last() |> String.to_atom()

      {_, term} ->
        RDF.Term.value(term)
    end

    assert Graph.new() |> Graph.map(mapping) == %{}

    assert Graph.new([{EX.s1(), EX.p(), EX.o1()}, {EX.s2(), EX.p(), EX.o2()}])
           |> Graph.map(mapping) ==
             %{
               RDF.Term.value(EX.s1()) => %{p: [RDF.Term.value(EX.o1())]},
               RDF.Term.value(EX.s2()) => %{p: [RDF.Term.value(EX.o2())]}
             }
  end

  describe "take/2" do
    test "with a non-empty subject list" do
      assert Graph.new([{EX.s1(), EX.p(), EX.o1()}, {EX.s2(), EX.p(), EX.o2()}])
             |> Graph.take([EX.s2(), EX.s3()]) ==
               Graph.new([{EX.s2(), EX.p(), EX.o2()}])
    end

    test "with an empty subject list" do
      assert Graph.new([{EX.s1(), EX.p(), EX.o1()}, {EX.s2(), EX.p(), EX.o2()}])
             |> Graph.take([]) == Graph.new()
    end

    test "with nil" do
      assert Graph.new([{EX.s1(), EX.p(), EX.o1()}, {EX.s2(), EX.p(), EX.o2()}])
             |> Graph.take(nil) ==
               Graph.new([{EX.s1(), EX.p(), EX.o1()}, {EX.s2(), EX.p(), EX.o2()}])
    end
  end

  describe "take/3" do
    test "with non-empty subject and property lists" do
      assert Graph.new([
               {EX.s1(), EX.p1(), EX.o1()},
               {EX.s1(), EX.p2(), EX.o1()},
               {EX.s2(), EX.p1(), EX.o2()}
             ])
             |> Graph.take([EX.s1(), EX.s3()], [EX.p2()]) ==
               Graph.new([{EX.s1(), EX.p2(), EX.o1()}])
    end

    test "with an empty subject list" do
      assert Graph.new(
               [
                 {EX.s1(), EX.p1(), EX.o1()},
                 {EX.s1(), EX.p2(), EX.o1()},
                 {EX.s2(), EX.p1(), EX.o2()}
               ],
               name: EX.Graph
             )
             |> Graph.take([], [EX.p1()]) == Graph.new(name: EX.Graph)
    end

    test "with nil" do
      assert Graph.new([
               {EX.s1(), EX.p1(), EX.o1()},
               {EX.s1(), EX.p2(), EX.o1()},
               {EX.s2(), EX.p1(), EX.o2()}
             ])
             |> Graph.take(nil, [EX.p1()]) ==
               Graph.new([{EX.s1(), EX.p1(), EX.o1()}, {EX.s2(), EX.p1(), EX.o2()}])
    end
  end

  test "equal/2" do
    assert Graph.new({EX.S, EX.p(), EX.O})
           |> Graph.equal?(Graph.new({EX.S, EX.p(), EX.O}))

    assert Graph.new({EX.S, EX.p(), EX.O}, name: EX.Graph1)
           |> Graph.equal?(Graph.new({EX.S, EX.p(), EX.O}, name: EX.Graph1))

    assert Graph.new({EX.S, EX.p(), EX.O}, prefixes: %{ex: EX})
           |> Graph.equal?(Graph.new({EX.S, EX.p(), EX.O}, prefixes: %{xsd: XSD}))

    assert Graph.new({EX.S, EX.p(), EX.O}, base_iri: EX.base())
           |> Graph.equal?(Graph.new({EX.S, EX.p(), EX.O}, base_iri: EX.other_base()))

    refute Graph.new({EX.S, EX.p(), EX.O})
           |> Graph.equal?(Graph.new({EX.S, EX.p(), EX.O2}))

    refute Graph.new({EX.S, EX.p(), EX.O}, name: EX.Graph1)
           |> Graph.equal?(Graph.new({EX.S, EX.p(), EX.O}, name: EX.Graph2))
  end

  test "prefixes/1" do
    assert Graph.prefixes(graph()) == nil
    assert %Graph{prefixes: PrefixMap.new()} |> Graph.prefixes() == PrefixMap.new()
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
      graph =
        Graph.new(prefixes: %{ex: EX}) |> Graph.add_prefixes([ex: XSD], fn _, ns, _ -> ns end)

      assert graph.prefixes == PrefixMap.new(ex: EX)
    end
  end

  describe "delete_prefixes/2" do
    test "when given a single prefix" do
      graph = Graph.new(prefixes: %{ex: EX}) |> Graph.delete_prefixes(:ex)
      assert graph.prefixes == PrefixMap.new()
    end

    test "when given a list of prefixes" do
      graph =
        Graph.new(prefixes: %{ex1: EX, ex2: EX}) |> Graph.delete_prefixes([:ex1, :ex2, :ex3])

      assert graph.prefixes == PrefixMap.new()
    end

    test "when prefixes are not defined yet" do
      graph = Graph.new() |> Graph.delete_prefixes(:ex)
      assert graph.prefixes == nil
    end
  end

  test "clear_prefixes/1" do
    assert Graph.clear_prefixes(Graph.new(prefixes: %{ex: EX})) == Graph.new()
  end

  test "base_iri/1" do
    assert Graph.base_iri(graph()) == nil

    assert %Graph{base_iri: ~I<http://example.com/>} |> Graph.base_iri() ==
             ~I<http://example.com/>
  end

  describe "set_base_iri/1" do
    test "when given an IRI" do
      graph = Graph.new() |> Graph.set_base_iri(~I<http://example.com/>)
      assert graph.base_iri == ~I<http://example.com/>
    end

    test "when given a term atom under a vocabulary namespace" do
      graph = Graph.new() |> Graph.set_base_iri(EX.Base)
      assert graph.base_iri == RDF.iri(EX.Base)
    end

    test "when given a vocabulary namespace module" do
      graph = Graph.new() |> Graph.set_base_iri(EX)
      assert graph.base_iri == RDF.iri(EX.__base_iri__())
    end

    test "when given nil" do
      graph = Graph.new() |> Graph.set_base_iri(nil)
      assert graph.base_iri == nil
    end
  end

  test "clear_base_iri/1" do
    assert Graph.clear_base_iri(Graph.new(base_iri: EX.base())) == Graph.new()
  end

  test "clear_metadata/1" do
    assert Graph.clear_metadata(Graph.new(base_iri: EX.base(), prefixes: %{ex: EX})) ==
             Graph.new()
  end

  test "triples/1" do
    assert Graph.new([
             {EX.S1, EX.p1(), EX.O1},
             {EX.S2, EX.p2(), EX.O2},
             {EX.S1, EX.p3(), EX.O3}
           ])
           |> Graph.triples() ==
             [
               {RDF.iri(EX.S1), EX.p1(), RDF.iri(EX.O1)},
               {RDF.iri(EX.S1), EX.p3(), RDF.iri(EX.O3)},
               {RDF.iri(EX.S2), EX.p2(), RDF.iri(EX.O2)}
             ]
  end

  describe "Enumerable protocol" do
    test "Enum.count" do
      assert Enum.count(Graph.new(name: EX.foo())) == 0
      assert Enum.count(Graph.new({EX.S, EX.p(), EX.O})) == 1
      assert Enum.count(Graph.new([{EX.S, EX.p(), EX.O1}, {EX.S, EX.p(), EX.O2}])) == 2

      g =
        Graph.add(graph(), [
          {EX.Subject1, EX.predicate1(), EX.Object1},
          {EX.Subject1, EX.predicate2(), EX.Object2},
          {EX.Subject3, EX.predicate3(), EX.Object3}
        ])

      assert Enum.count(g) == 3
    end

    test "Enum.member?" do
      refute Enum.member?(Graph.new(), {iri(EX.S), EX.p(), iri(EX.O)})
      assert Enum.member?(Graph.new({EX.S, EX.p(), EX.O}), {EX.S, EX.p(), EX.O})

      g =
        Graph.add(graph(), [
          {EX.Subject1, EX.predicate1(), EX.Object1},
          {EX.Subject1, EX.predicate2(), EX.Object2},
          {EX.Subject3, EX.predicate3(), EX.Object3}
        ])

      assert Enum.member?(g, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert Enum.member?(g, {EX.Subject1, EX.predicate2(), EX.Object2})
      assert Enum.member?(g, {EX.Subject3, EX.predicate3(), EX.Object3})
    end

    test "Enum.reduce" do
      g =
        Graph.add(graph(), [
          {EX.Subject1, EX.predicate1(), EX.Object1},
          {EX.Subject1, EX.predicate2(), EX.Object2},
          {EX.Subject3, EX.predicate3(), EX.Object3}
        ])

      assert g == Enum.reduce(g, graph(), fn triple, acc -> acc |> Graph.add(triple) end)
    end

    test "Enum.at (for Enumerable.slice/1)" do
      assert Graph.new({EX.S, EX.p(), EX.O})
             |> Enum.at(0) == {RDF.iri(EX.S), EX.p(), RDF.iri(EX.O)}
    end
  end

  describe "Collectable protocol" do
    test "with a list of triples" do
      triples = [
        {EX.Subject, EX.predicate1(), EX.Object1},
        {EX.Subject, EX.predicate2(), EX.Object2}
      ]

      assert Enum.into(triples, Graph.new()) == Graph.new(triples)
    end

    test "with a list of lists" do
      lists = [
        [EX.Subject, EX.predicate1(), EX.Object1],
        [EX.Subject, EX.predicate2(), EX.Object2]
      ]

      assert Enum.into(lists, Graph.new()) ==
               Graph.new(Enum.map(lists, &List.to_tuple/1))
    end
  end

  describe "Access behaviour" do
    test "access with the [] operator" do
      assert Graph.new()[EX.Subject] == nil

      assert Graph.new({EX.S, EX.p(), EX.O})[EX.S] ==
               Description.new(EX.S, init: {EX.p(), EX.O})
    end
  end
end
