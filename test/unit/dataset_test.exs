defmodule RDF.DatasetTest do
  use RDF.Test.Case

  doctest RDF.Dataset


  describe "new" do
    test "creating an empty unnamed dataset" do
      assert unnamed_dataset?(unnamed_dataset())
    end

    test "creating an empty dataset with a proper dataset name" do
      refute unnamed_dataset?(named_dataset())
      assert named_dataset?(named_dataset())
    end

    test "creating an empty dataset with a convertible dataset name" do
      assert named_dataset("http://example.com/DatasetName")
             |> named_dataset?(uri("http://example.com/DatasetName"))
      assert named_dataset(EX.Foo) |> named_dataset?(uri(EX.Foo))
    end

    test "creating an unnamed dataset with an initial triple" do
      ds = Dataset.new({EX.Subject, EX.predicate, EX.Object})
      assert unnamed_dataset?(ds)
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating an unnamed dataset with an initial quad" do
      ds = Dataset.new({EX.Subject, EX.predicate, EX.Object, EX.GraphName})
      assert unnamed_dataset?(ds)
      assert dataset_includes_statement?(ds,
        {EX.Subject, EX.predicate, EX.Object, EX.GraphName})
    end

    test "creating a named dataset with an initial triple" do
      ds = Dataset.new(EX.DatasetName, {EX.Subject, EX.predicate, EX.Object})
      assert named_dataset?(ds, uri(EX.DatasetName))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating a named dataset with an initial quad" do
      ds = Dataset.new(EX.DatasetName, {EX.Subject, EX.predicate, EX.Object, EX.GraphName})
      assert named_dataset?(ds, uri(EX.DatasetName))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object, EX.GraphName})
    end

    test "creating an unnamed dataset with a list of initial statements" do
      ds = Dataset.new([
              {EX.Subject1, EX.predicate1, EX.Object1},
              {EX.Subject2, EX.predicate2, EX.Object2, EX.GraphName},
              {EX.Subject3, EX.predicate3, EX.Object3, nil}
           ])
      assert unnamed_dataset?(ds)
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1, nil})
      assert dataset_includes_statement?(ds, {EX.Subject2, EX.predicate2, EX.Object2, EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.Subject3, EX.predicate3, EX.Object3, nil})
    end

    test "creating a named dataset with a list of initial statements" do
      ds = Dataset.new(EX.DatasetName, [
              {EX.Subject, EX.predicate1, EX.Object1},
              {EX.Subject, EX.predicate2, EX.Object2, EX.GraphName},
              {EX.Subject, EX.predicate3, EX.Object3, nil}
           ])
      assert named_dataset?(ds, uri(EX.DatasetName))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1, EX.Object1, nil})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate2, EX.Object2, EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate3, EX.Object3, nil})
    end

    test "creating a named dataset with an initial description" do
      ds = Dataset.new(EX.DatasetName, Description.new({EX.Subject, EX.predicate, EX.Object}))
      assert named_dataset?(ds, uri(EX.DatasetName))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating an unnamed dataset with an initial description" do
      ds = Dataset.new(Description.new({EX.Subject, EX.predicate, EX.Object}))
      assert unnamed_dataset?(ds)
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object})
    end

    test "creating a named dataset with an inital graph" do
      ds = Dataset.new(EX.DatasetName, Graph.new({EX.Subject, EX.predicate, EX.Object}))
      assert named_dataset?(ds, uri(EX.DatasetName))
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object})

      ds = Dataset.new(EX.DatasetName, Graph.new(EX.GraphName, {EX.Subject, EX.predicate, EX.Object}))
      assert named_dataset?(ds, uri(EX.DatasetName))
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert named_graph?(Dataset.graph(ds, EX.GraphName), uri(EX.GraphName))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object, EX.GraphName})
    end

    test "creating an unnamed dataset with an inital graph" do
      ds = Dataset.new(Graph.new({EX.Subject, EX.predicate, EX.Object}))
      assert unnamed_dataset?(ds)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object})

      ds = Dataset.new(Graph.new(EX.GraphName, {EX.Subject, EX.predicate, EX.Object}))
      assert unnamed_dataset?(ds)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert named_graph?(Dataset.graph(ds, EX.GraphName), uri(EX.GraphName))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object, EX.GraphName})
    end
  end

  describe "add" do
    test "a proper triple is added to the default graph" do
      assert Dataset.add(dataset(), {uri(EX.Subject), EX.predicate, uri(EX.Object)})
        |> dataset_includes_statement?({EX.Subject, EX.predicate, EX.Object})
    end

    test "a proper quad is added to the specified graph" do
      ds = Dataset.add(dataset(), {uri(EX.Subject), EX.predicate, uri(EX.Object), uri(EX.Graph)})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object, uri(EX.Graph)})
    end

    test "a proper quad with nil context is added to the default graph" do
      ds = Dataset.add(dataset(), {uri(EX.Subject), EX.predicate, uri(EX.Object), nil})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate, EX.Object})
    end


    test "a convertible triple" do
      assert Dataset.add(dataset(),
          {"http://example.com/Subject", EX.predicate, EX.Object})
        |> dataset_includes_statement?({EX.Subject, EX.predicate, EX.Object})
    end

    test "a convertible quad" do
      assert Dataset.add(dataset(),
          {"http://example.com/Subject", EX.predicate, EX.Object, "http://example.com/GraphName"})
        |> dataset_includes_statement?({EX.Subject, EX.predicate, EX.Object, EX.GraphName})
    end

    test "statements with multiple objects" do
      ds = Dataset.add(dataset(), {EX.Subject1, EX.predicate1, [EX.Object1, EX.Object2]})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object2})

      ds = Dataset.add(dataset(), {EX.Subject1, EX.predicate1, [EX.Object1, EX.Object2], EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1, EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object2, EX.GraphName})
    end

    test "a list of triples without specification the default context" do
      ds = Dataset.add(dataset(), [
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
        {EX.Subject3, EX.predicate3, EX.Object3}
      ])
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject3, EX.predicate3, EX.Object3})
    end

    test "a list of triples with specification the default context" do
      ds = Dataset.add(dataset(), [
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
        {EX.Subject3, EX.predicate3, EX.Object3, nil}
      ], EX.Graph)
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject3, EX.predicate3, EX.Object3, nil})
    end

    test "a list of quads" do
      ds = Dataset.add(dataset(), [
        {EX.Subject, EX.predicate1, EX.Object1, EX.Graph1},
        {EX.Subject, EX.predicate2, EX.Object2, nil},
        {EX.Subject, EX.predicate1, EX.Object1, EX.Graph2}
      ])
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1, EX.Object1, EX.Graph1})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate2, EX.Object2, nil})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1, EX.Object1, EX.Graph2})
    end

    test "a list of mixed triples and quads" do
      ds = Dataset.add(dataset(), [
        {EX.Subject1, EX.predicate1, EX.Object1, EX.GraphName},
        {EX.Subject3, EX.predicate3, EX.Object3}
      ])
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1, EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.Subject3, EX.predicate3, EX.Object3, nil})
    end

    test "a Description" do
      ds = Dataset.add(dataset(), Description.new(EX.Subject1, [
        {EX.predicate1, EX.Object1},
        {EX.predicate2, EX.Object2},
      ]))
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})

      ds = Dataset.add(ds, Description.new({EX.Subject1, EX.predicate3, EX.Object3}), EX.Graph)
      assert Enum.count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate3, EX.Object3, EX.Graph})
    end

    test "an unnamed Graph" do
      ds = Dataset.add(dataset(), Graph.new([
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
      ]))
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})

      ds = Dataset.add(ds, Graph.new({EX.Subject1, EX.predicate2, EX.Object3}))
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert Enum.count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3})

      ds = Dataset.add(ds, Graph.new({EX.Subject1, EX.predicate2, EX.Object3}), EX.Graph)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert named_graph?(Dataset.graph(ds, EX.Graph), uri(EX.Graph))
      assert Enum.count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3, EX.Graph})
    end

    test "a named Graph" do
      ds = Dataset.add(dataset(), Graph.new(EX.Graph1, [
        {EX.Subject1, EX.predicate1, EX.Object1},
        {EX.Subject1, EX.predicate2, EX.Object2},
      ]))
      refute Dataset.graph(ds, EX.Graph1)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})

      ds = Dataset.add(ds, Graph.new(EX.Graph2, {EX.Subject1, EX.predicate2, EX.Object3}))
      refute Dataset.graph(ds, EX.Graph2)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert Enum.count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3})

      ds = Dataset.add(ds, Graph.new(EX.Graph3, {EX.Subject1, EX.predicate2, EX.Object3}), EX.Graph)
      assert named_graph?(Dataset.graph(ds, EX.Graph), uri(EX.Graph))
      assert Enum.count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2, EX.Object3, EX.Graph})
    end

    test "a list of Descriptions" do
      ds = Dataset.add(dataset(), [
        Description.new({EX.Subject1, EX.predicate1, EX.Object1}),
        Description.new({EX.Subject2, EX.predicate2, EX.Object2}),
        Description.new({EX.Subject1, EX.predicate3, EX.Object3})
      ])
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject2, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate3, EX.Object3})

      ds = Dataset.add(ds, [
        Description.new({EX.Subject1, EX.predicate1, EX.Object1}),
        Description.new({EX.Subject2, EX.predicate2, EX.Object2}),
        Description.new({EX.Subject1, EX.predicate3, EX.Object3})
      ], EX.Graph)
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject2, EX.predicate2, EX.Object2, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate3, EX.Object3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1, EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject2, EX.predicate2, EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate3, EX.Object3})
    end

    @tag skip: "TODO"
    test "a list of Graphs" do
    end

    test "duplicates are ignored" do
      ds = Dataset.add(dataset(), {EX.Subject, EX.predicate, EX.Object, EX.GraphName})
      assert Dataset.add(ds, {EX.Subject, EX.predicate, EX.Object, EX.GraphName}) == ds
    end

    test "non-convertible statements elements are causing an error" do
      assert_raise RDF.InvalidURIError, fn ->
        Dataset.add(dataset(), {"not a URI", EX.predicate, uri(EX.Object), uri(EX.GraphName)})
      end
      assert_raise RDF.InvalidLiteralError, fn ->
        Dataset.add(dataset(), {EX.Subject, EX.prop, self(), nil})
      end
      assert_raise RDF.InvalidURIError, fn ->
        Dataset.add(dataset(), {uri(EX.Subject), EX.predicate, uri(EX.Object), "not a URI"})
      end
    end
  end

  describe "put" do
    test "a list of triples" do
      ds = Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2, EX.Graph}])
        |> RDF.Dataset.put([
              {EX.S1, EX.P2, EX.O3, EX.Graph},
              {EX.S1, EX.P2, bnode(:foo), nil},
              {EX.S2, EX.P2, EX.O3, EX.Graph},
              {EX.S2, EX.P2, EX.O4, EX.Graph}])

      assert Dataset.statement_count(ds) == 5
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O4, EX.Graph})
    end

    test "a Description" do
      ds = Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}, {EX.S1, EX.P3, EX.O3}])
        |> RDF.Dataset.put(Description.new(EX.S1, [{EX.P3, EX.O4}, {EX.P2, bnode(:foo)}]))

      assert Dataset.statement_count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2})
    end

    test "an unnamed Graph" do
      ds = Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}, {EX.S1, EX.P3, EX.O3}])
        |> RDF.Dataset.put(Graph.new([{EX.S1, EX.P3, EX.O4}, {EX.S1, EX.P2, bnode(:foo)}]))

      assert Dataset.statement_count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2})
    end

    test "a named Graph" do
      ds = Dataset.new(
            Graph.new(EX.GraphName, [{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}, {EX.S1, EX.P3, EX.O3}]))
        |> RDF.Dataset.put(
            Graph.new([{EX.S1, EX.P3, EX.O4}, {EX.S1, EX.P2, bnode(:foo)}]), EX.GraphName)

      assert Dataset.statement_count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1, EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4, EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo), EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2, EX.GraphName})
    end

#    @tag skip: "TODO: Requires Dataset.put with a list to differentiate a list of statements, a list of Descriptions and list of Graphs. Do we want to support mixed lists also?"
#    test "a list of Descriptions" do
#      ds = Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}])
#        |> RDF.Dataset.put([
#            Description.new(EX.S1, [{EX.P2, EX.O3}, {EX.P2, bnode(:foo)}]),
#            Description.new(EX.S2, [{EX.P2, EX.O3}, {EX.P2, EX.O4}])
#           ])
#
#        assert Dataset.triple_count(ds) == 5
#        assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
#        assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O3})
#        assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
#        assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O3})
#        assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O4})
#    end

    test "simultaneous use of the different forms to address the default context" do
      ds = RDF.Dataset.put(dataset(), [
            {EX.S, EX.P, EX.O1},
            {EX.S, EX.P, EX.O2, nil}])
      assert Dataset.statement_count(ds) == 2
      assert dataset_includes_statement?(ds, {EX.S, EX.P, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S, EX.P, EX.O2})

# TODO: see comment on RDF.Dataset.put on why the following is not supported
#      ds = RDF.Dataset.put(dataset(), %{
#            EX.S        => [{EX.P, EX.O1}],
#            {EX.S, nil} => [{EX.P, EX.O2}]
#      })
#      assert Dataset.statement_count(ds) == 2
#      assert dataset_includes_statement?(ds, {EX.S, EX.P, EX.O1})
#      assert dataset_includes_statement?(ds, {EX.S, EX.P, EX.O2})
    end
  end

  test "pop" do
    assert Dataset.pop(Dataset.new) == {nil, Dataset.new}

    {quad, dataset} = Dataset.new({EX.S, EX.p, EX.O, EX.Graph}) |> Dataset.pop
    assert quad == {uri(EX.S), uri(EX.p), uri(EX.O), uri(EX.Graph)}
    assert Enum.count(dataset.graphs) == 0

    {{subject, predicate, object, _}, dataset} =
      Dataset.new([{EX.S, EX.p, EX.O, EX.Graph}, {EX.S, EX.p, EX.O}])
      |> Dataset.pop
    assert {subject, predicate, object} == {uri(EX.S), uri(EX.p), uri(EX.O)}
    assert Enum.count(dataset.graphs) == 1

    {{subject, _, _, graph_context}, dataset} =
      Dataset.new([{EX.S, EX.p, EX.O1, EX.Graph}, {EX.S, EX.p, EX.O2, EX.Graph}])
      |> Dataset.pop
    assert subject == uri(EX.S)
    assert graph_context == uri(EX.Graph)
    assert Enum.count(dataset.graphs) == 1
  end

  describe "Enumerable protocol" do
    test "Enum.count" do
      assert Enum.count(Dataset.new EX.foo) == 0
      assert Enum.count(Dataset.new {EX.S, EX.p, EX.O, EX.Graph}) == 1
      assert Enum.count(Dataset.new [{EX.S, EX.p, EX.O1, EX.Graph}, {EX.S, EX.p, EX.O2}]) == 2

      ds = Dataset.add(dataset(), [
        {EX.Subject1, EX.predicate1, EX.Object1, EX.Graph},
        {EX.Subject1, EX.predicate2, EX.Object2, EX.Graph},
        {EX.Subject3, EX.predicate3, EX.Object3}
      ])
      assert Enum.count(ds) == 3
    end

    test "Enum.member?" do
      refute Enum.member?(Dataset.new, {uri(EX.S), EX.p, uri(EX.O), uri(EX.Graph)})
      assert Enum.member?(Dataset.new({EX.S, EX.p, EX.O, EX.Graph}),
                                      {EX.S, EX.p, EX.O, EX.Graph})

      ds = Dataset.add(dataset(), [
        {EX.Subject1, EX.predicate1, EX.Object1, EX.Graph},
        {EX.Subject1, EX.predicate2, EX.Object2, EX.Graph},
        {EX.Subject3, EX.predicate3, EX.Object3}
      ])
      assert Enum.member?(ds, {EX.Subject1, EX.predicate1, EX.Object1, EX.Graph})
      assert Enum.member?(ds, {EX.Subject1, EX.predicate2, EX.Object2, EX.Graph})
      assert Enum.member?(ds, {EX.Subject3, EX.predicate3, EX.Object3})
    end

    test "Enum.reduce" do
      ds = Dataset.add(dataset(), [
        {EX.Subject1, EX.predicate1, EX.Object1, EX.Graph},
        {EX.Subject1, EX.predicate2, EX.Object2},
        {EX.Subject3, EX.predicate3, EX.Object3, EX.Graph}
      ])

      assert ds == Enum.reduce(ds, dataset(),
        fn(statement, acc) -> acc |> Dataset.add(statement) end)
    end
  end

  describe "Access behaviour" do
    test "access with the [] operator" do
      assert Dataset.new[EX.Graph] == nil
      assert Dataset.new({EX.S, EX.p, EX.O, EX.Graph})[EX.Graph] ==
              Graph.new(EX.Graph, {EX.S, EX.p, EX.O})
    end
  end

end
