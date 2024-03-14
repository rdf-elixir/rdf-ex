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

    test "creating an empty dataset with a coercible dataset name" do
      assert named_dataset("http://example.com/DatasetName")
             |> named_dataset?(~I<http://example.com/DatasetName>)

      assert named_dataset(EX.Foo) |> named_dataset?(RDF.iri(EX.Foo))
    end

    test "creating an unnamed dataset with an initial triple" do
      ds = Dataset.new({EX.Subject, EX.predicate(), EX.Object})
      assert unnamed_dataset?(ds)
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate(), EX.Object})
    end

    test "creating an unnamed dataset with an initial quad" do
      ds = Dataset.new({EX.Subject, EX.predicate(), EX.Object, EX.GraphName})
      assert unnamed_dataset?(ds)

      assert dataset_includes_statement?(
               ds,
               {EX.Subject, EX.predicate(), EX.Object, EX.GraphName}
             )
    end

    test "creating a named dataset with an initial triple" do
      ds = Dataset.new({EX.Subject, EX.predicate(), EX.Object}, name: EX.DatasetName)
      assert named_dataset?(ds, RDF.iri(EX.DatasetName))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate(), EX.Object})
    end

    test "creating a named dataset with an initial quad" do
      ds =
        Dataset.new({EX.Subject, EX.predicate(), EX.Object, EX.GraphName}, name: EX.DatasetName)

      assert named_dataset?(ds, RDF.iri(EX.DatasetName))

      assert dataset_includes_statement?(
               ds,
               {EX.Subject, EX.predicate(), EX.Object, EX.GraphName}
             )
    end

    test "creating an unnamed dataset with a list of initial statements" do
      ds =
        Dataset.new([
          {EX.Subject1, EX.predicate1(), EX.Object1},
          {EX.Subject2, EX.predicate2(), EX.Object2, EX.GraphName},
          {EX.Subject3, EX.predicate3(), EX.Object3, nil}
        ])

      assert unnamed_dataset?(ds)
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1, nil})

      assert dataset_includes_statement?(
               ds,
               {EX.Subject2, EX.predicate2(), EX.Object2, EX.GraphName}
             )

      assert dataset_includes_statement?(ds, {EX.Subject3, EX.predicate3(), EX.Object3, nil})
    end

    test "creating a named dataset with a list of initial statements" do
      ds =
        Dataset.new(
          [
            {EX.Subject, EX.predicate1(), EX.Object1},
            {EX.Subject, EX.predicate2(), EX.Object2, EX.GraphName},
            {EX.Subject, EX.predicate3(), EX.Object3, nil}
          ],
          name: EX.DatasetName
        )

      assert named_dataset?(ds, RDF.iri(EX.DatasetName))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1(), EX.Object1, nil})

      assert dataset_includes_statement?(
               ds,
               {EX.Subject, EX.predicate2(), EX.Object2, EX.GraphName}
             )

      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate3(), EX.Object3, nil})
    end

    test "creating a named dataset with an initial description" do
      ds =
        Description.new(EX.Subject, init: {EX.predicate(), EX.Object})
        |> Dataset.new(name: EX.DatasetName)

      assert named_dataset?(ds, RDF.iri(EX.DatasetName))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate(), EX.Object})
    end

    test "creating an unnamed dataset with an initial description" do
      ds =
        Description.new(EX.Subject, init: {EX.predicate(), EX.Object})
        |> Dataset.new()

      assert unnamed_dataset?(ds)
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate(), EX.Object})
    end

    test "creating a named dataset with an initial graph" do
      ds = Dataset.new(Graph.new({EX.Subject, EX.predicate(), EX.Object}), name: EX.DatasetName)
      assert named_dataset?(ds, RDF.iri(EX.DatasetName))
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate(), EX.Object})

      ds =
        Dataset.new(Graph.new({EX.Subject, EX.predicate(), EX.Object}, name: EX.GraphName),
          name: EX.DatasetName
        )

      assert named_dataset?(ds, RDF.iri(EX.DatasetName))
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert named_graph?(Dataset.graph(ds, EX.GraphName), RDF.iri(EX.GraphName))

      assert dataset_includes_statement?(
               ds,
               {EX.Subject, EX.predicate(), EX.Object, EX.GraphName}
             )
    end

    test "creating an unnamed dataset with an initial graph" do
      ds = Dataset.new(Graph.new({EX.Subject, EX.predicate(), EX.Object}))
      assert unnamed_dataset?(ds)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate(), EX.Object})

      ds = Dataset.new(Graph.new({EX.Subject, EX.predicate(), EX.Object}, name: EX.GraphName))
      assert unnamed_dataset?(ds)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert named_graph?(Dataset.graph(ds, EX.GraphName), RDF.iri(EX.GraphName))

      assert dataset_includes_statement?(
               ds,
               {EX.Subject, EX.predicate(), EX.Object, EX.GraphName}
             )
    end

    test "with a context" do
      ds = Dataset.new({EX.S, :p, EX.O}, context: [p: EX.p()])
      assert dataset_includes_statement?(ds, {EX.S, EX.p(), EX.O})
    end

    @tag skip: "This case is currently not supported, since it's indistinguishable from Keywords"
    test "creating a dataset with a list of subject-predications pairs" do
      ds =
        Dataset.new([
          {EX.S1,
           [
             {EX.P1, EX.O1},
             %{EX.P2 => [EX.O2]}
           ]}
        ])

      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O2})
    end

    test "with init data" do
      ds =
        Dataset.new(
          init: [
            {EX.S1,
             [
               {EX.P1, EX.O1},
               %{EX.P2 => [EX.O2]}
             ]}
          ]
        )

      assert unnamed_dataset?(ds)
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O2})

      ds =
        Dataset.new(
          name: EX.Dataset,
          init: {EX.S, EX.p(), EX.O}
        )

      assert named_dataset?(ds, RDF.iri(EX.Dataset))
      assert dataset_includes_statement?(ds, {EX.S, EX.p(), EX.O})
    end

    test "with an initializer function" do
      ds = Dataset.new(init: fn -> {EX.S, EX.p(), EX.O} end)
      assert unnamed_dataset?(ds)
      assert dataset_includes_statement?(ds, {EX.S, EX.p(), EX.O})
    end
  end

  test "name/1" do
    assert Dataset.name(dataset()) == dataset().name
  end

  test "change_name/2" do
    assert Dataset.change_name(dataset(), EX.NewDataset).name == RDF.iri(EX.NewDataset)
    assert Dataset.change_name(named_dataset(), nil).name == nil
  end

  describe "add/3" do
    test "a proper triple is added to the default graph" do
      assert Dataset.add(dataset(), {RDF.iri(EX.Subject), EX.predicate(), RDF.iri(EX.Object)})
             |> dataset_includes_statement?({EX.Subject, EX.predicate(), EX.Object})
    end

    test "a proper quad is added to the specified graph" do
      ds =
        Dataset.add(
          dataset(),
          {RDF.iri(EX.Subject), EX.predicate(), RDF.iri(EX.Object), RDF.iri(EX.Graph)}
        )

      assert dataset_includes_statement?(
               ds,
               {EX.Subject, EX.predicate(), EX.Object, RDF.iri(EX.Graph)}
             )
    end

    test "a proper quad with nil context is added to the default graph" do
      ds = Dataset.add(dataset(), {RDF.iri(EX.Subject), EX.predicate(), RDF.iri(EX.Object), nil})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate(), EX.Object})
    end

    test "a coercible triple" do
      assert Dataset.add(
               dataset(),
               {"http://example.com/Subject", EX.predicate(), EX.Object}
             )
             |> dataset_includes_statement?({EX.Subject, EX.predicate(), EX.Object})
    end

    test "a coercible quad" do
      assert Dataset.add(
               dataset(),
               {"http://example.com/Subject", EX.predicate(), EX.Object,
                "http://example.com/GraphName"}
             )
             |> dataset_includes_statement?({EX.Subject, EX.predicate(), EX.Object, EX.GraphName})
    end

    test "a quad and an overwriting graph context" do
      assert Dataset.add(dataset(), {EX.Subject, EX.predicate(), EX.Object, EX.Graph},
               graph: EX.Other
             )
             |> dataset_includes_statement?({EX.Subject, EX.predicate(), EX.Object, EX.Other})

      assert Dataset.add(dataset(), {EX.Subject, EX.predicate(), EX.Object, EX.Graph}, graph: nil)
             |> dataset_includes_statement?({EX.Subject, EX.predicate(), EX.Object})
    end

    test "statements with multiple objects" do
      ds = Dataset.add(dataset(), {EX.Subject1, EX.predicate1(), [EX.Object1, EX.Object2]})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object2})

      ds =
        Dataset.add(
          dataset(),
          {EX.Subject1, EX.predicate1(), [EX.Object1, EX.Object2], EX.GraphName}
        )

      assert dataset_includes_statement?(
               ds,
               {EX.Subject1, EX.predicate1(), EX.Object1, EX.GraphName}
             )

      assert dataset_includes_statement?(
               ds,
               {EX.Subject1, EX.predicate1(), EX.Object2, EX.GraphName}
             )
    end

    test "a list of triples without an overwriting graph context" do
      ds =
        Dataset.add(dataset(), [
          {EX.Subject1, EX.predicate1(), EX.Object1},
          {EX.Subject1, EX.predicate2(), EX.Object2},
          {EX.Subject3, EX.predicate3(), EX.Object3}
        ])

      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject3, EX.predicate3(), EX.Object3})
    end

    test "a list of triples with an overwriting graph context" do
      ds =
        Dataset.add(
          dataset(),
          [
            {EX.Subject1, EX.predicate1(), EX.Object1},
            {EX.Subject1, EX.predicate2(), EX.Object2},
            {EX.Subject3, EX.predicate3(), EX.Object3}
          ],
          graph: EX.Graph
        )

      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject3, EX.predicate3(), EX.Object3, EX.Graph})

      ds =
        Dataset.add(
          dataset(),
          [
            {EX.Subject1, EX.predicate1(), EX.Object1},
            {EX.Subject1, EX.predicate2(), EX.Object2},
            {EX.Subject3, EX.predicate3(), EX.Object3}
          ],
          graph: nil
        )

      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1, nil})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2, nil})
      assert dataset_includes_statement?(ds, {EX.Subject3, EX.predicate3(), EX.Object3, nil})
    end

    test "a list of quads without an overwriting graph context" do
      ds =
        Dataset.add(dataset(), [
          {EX.Subject, EX.predicate1(), EX.Object1, EX.Graph1},
          {EX.Subject, EX.predicate2(), EX.Object2, nil},
          {EX.Subject, EX.predicate1(), EX.Object1, EX.Graph2}
        ])

      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1(), EX.Object1, EX.Graph1})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate2(), EX.Object2, nil})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1(), EX.Object1, EX.Graph2})
    end

    test "a list of quads with an overwriting graph context" do
      ds =
        Dataset.add(
          dataset(),
          [
            {EX.Subject, EX.predicate1(), EX.Object1, EX.Graph1},
            {EX.Subject, EX.predicate2(), EX.Object2, nil},
            {EX.Subject, EX.predicate1(), EX.Object1, EX.Graph2}
          ],
          graph: EX.Graph
        )

      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1(), EX.Object1, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate2(), EX.Object2, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1(), EX.Object1, EX.Graph})

      ds =
        Dataset.add(
          dataset(),
          [
            {EX.Subject, EX.predicate1(), EX.Object1, EX.Graph1},
            {EX.Subject, EX.predicate2(), EX.Object2, nil},
            {EX.Subject, EX.predicate1(), EX.Object1, EX.Graph2}
          ],
          graph: nil
        )

      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1(), EX.Object1, nil})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate2(), EX.Object2, nil})
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate1(), EX.Object1, nil})
    end

    test "a list of mixed triples and quads" do
      ds =
        Dataset.add(dataset(), [
          {EX.S1, EX.p1(), EX.O1, EX.Graph},
          {EX.S3, EX.p3(), EX.O3}
        ])

      assert dataset_includes_statement?(ds, {EX.S1, EX.p1(), EX.O1, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S3, EX.p3(), EX.O3, nil})

      ds =
        Dataset.add(
          dataset(),
          [
            {EX.S1, EX.p1(), EX.O1, EX.Graph},
            {EX.S3, EX.p3(), EX.O3}
          ],
          graph: EX.Graph2
        )

      assert dataset_includes_statement?(ds, {EX.S1, EX.p1(), EX.O1, EX.Graph2})
      assert dataset_includes_statement?(ds, {EX.S3, EX.p3(), EX.O3, EX.Graph2})
    end

    test "a map without an overwriting graph context" do
      ds =
        Dataset.add(dataset(), %{
          EX.Subject1 => %{
            EX.predicate1() => EX.Object1,
            EX.predicate2() => EX.Object2
          },
          EX.Subject3 => {EX.predicate3(), EX.Object3}
        })

      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject3, EX.predicate3(), EX.Object3})
    end

    test "a map with an overwriting graph context" do
      ds =
        Dataset.add(
          dataset(),
          %{
            EX.Subject1 => [
              {EX.predicate2(), EX.Object2},
              {EX.predicate1(), EX.Object1}
            ],
            EX.Subject3 => %{EX.predicate3() => EX.Object3}
          },
          graph: EX.Graph
        )

      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject3, EX.predicate3(), EX.Object3, EX.Graph})

      ds =
        Dataset.add(
          dataset(),
          [
            {EX.Subject1, EX.predicate1(), EX.Object1},
            {EX.Subject1, EX.predicate2(), EX.Object2},
            {EX.Subject3, EX.predicate3(), EX.Object3}
          ],
          graph: nil
        )

      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1, nil})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2, nil})
      assert dataset_includes_statement?(ds, {EX.Subject3, EX.predicate3(), EX.Object3, nil})
    end

    test "a description without an overwriting graph context" do
      ds =
        Dataset.add(
          dataset(),
          Description.new(EX.Subject1)
          |> Description.add([
            {EX.predicate1(), EX.Object1},
            {EX.predicate2(), EX.Object2}
          ])
        )

      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})
    end

    test "a description with an overwriting graph context" do
      ds =
        Dataset.add(
          dataset(),
          Description.new(EX.Subject1,
            init: [
              {EX.predicate1(), EX.Object1},
              {EX.predicate2(), EX.Object2}
            ]
          ),
          graph: nil
        )

      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})

      ds =
        Dataset.add(
          ds,
          Description.new(EX.Subject1, init: {EX.predicate3(), EX.Object3}),
          graph: EX.Graph
        )

      assert Enum.count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate3(), EX.Object3, EX.Graph})
    end

    test "an unnamed graph without an overwriting graph context" do
      ds =
        Dataset.add(
          dataset(),
          Graph.new([
            {EX.Subject1, EX.predicate1(), EX.Object1},
            {EX.Subject1, EX.predicate2(), EX.Object2}
          ])
        )

      assert unnamed_graph?(Dataset.default_graph(ds))
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})

      ds = Dataset.add(ds, Graph.new({EX.Subject1, EX.predicate2(), EX.Object3}))
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert Enum.count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object3})
    end

    test "an unnamed graph with an overwriting graph context" do
      ds =
        Dataset.add(
          dataset(),
          Graph.new([
            {EX.Subject1, EX.predicate1(), EX.Object1},
            {EX.Subject1, EX.predicate2(), EX.Object2}
          ]),
          graph: nil
        )

      assert unnamed_graph?(Dataset.default_graph(ds))
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})

      ds = Dataset.add(ds, Graph.new({EX.Subject1, EX.predicate2(), EX.Object3}), graph: nil)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert Enum.count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object3})

      ds = Dataset.add(ds, Graph.new({EX.Subject1, EX.predicate2(), EX.Object3}), graph: EX.Graph)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert named_graph?(Dataset.graph(ds, EX.Graph), RDF.iri(EX.Graph))
      assert Enum.count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object3})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object3, EX.Graph})
    end

    test "a named graph without an overwriting graph context" do
      ds =
        Dataset.add(
          dataset(),
          Graph.new(
            [
              {EX.Subject1, EX.predicate1(), EX.Object1},
              {EX.Subject1, EX.predicate2(), EX.Object2}
            ],
            name: EX.Graph1
          )
        )

      assert Dataset.graph(ds, EX.Graph1)
      assert named_graph?(Dataset.graph(ds, EX.Graph1), RDF.iri(EX.Graph1))
      assert unnamed_graph?(Dataset.default_graph(ds))

      assert dataset_includes_statement?(
               ds,
               {EX.Subject1, EX.predicate1(), EX.Object1, EX.Graph1}
             )

      assert dataset_includes_statement?(
               ds,
               {EX.Subject1, EX.predicate2(), EX.Object2, EX.Graph1}
             )

      ds = Dataset.add(ds, Graph.new({EX.Subject1, EX.predicate2(), EX.Object3}, name: EX.Graph2))
      assert Dataset.graph(ds, EX.Graph2)
      assert named_graph?(Dataset.graph(ds, EX.Graph2), RDF.iri(EX.Graph2))
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert Enum.count(ds) == 3

      assert dataset_includes_statement?(
               ds,
               {EX.Subject1, EX.predicate1(), EX.Object1, EX.Graph1}
             )

      assert dataset_includes_statement?(
               ds,
               {EX.Subject1, EX.predicate2(), EX.Object2, EX.Graph1}
             )

      assert dataset_includes_statement?(
               ds,
               {EX.Subject1, EX.predicate2(), EX.Object3, EX.Graph2}
             )
    end

    test "a named graph with an overwriting graph context" do
      ds =
        Dataset.add(
          dataset(),
          Graph.new(
            [
              {EX.Subject1, EX.predicate1(), EX.Object1},
              {EX.Subject1, EX.predicate2(), EX.Object2}
            ],
            name: EX.Graph1
          ),
          graph: nil
        )

      refute Dataset.graph(ds, EX.Graph1)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})

      ds =
        Dataset.add(
          ds,
          Graph.new({EX.Subject1, EX.predicate2(), EX.Object3}, name: EX.Graph2),
          graph: nil
        )

      refute Dataset.graph(ds, EX.Graph2)
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert Enum.count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object3})

      ds =
        Dataset.add(
          ds,
          Graph.new({EX.Subject1, EX.predicate2(), EX.Object3}, name: EX.Graph3),
          graph: EX.Graph
        )

      assert named_graph?(Dataset.graph(ds, EX.Graph), RDF.iri(EX.Graph))
      assert Enum.count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object3})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object3, EX.Graph})
    end

    test "an unnamed dataset" do
      ds =
        Dataset.add(
          dataset(),
          Dataset.new([
            {EX.Subject1, EX.predicate1(), EX.Object1},
            {EX.Subject1, EX.predicate2(), EX.Object2}
          ])
        )

      assert ds.name == nil
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})

      ds = Dataset.add(ds, Dataset.new({EX.Subject1, EX.predicate2(), EX.Object3}))
      ds = Dataset.add(ds, Dataset.new({EX.Subject1, EX.predicate2(), EX.Object3, EX.Graph}))

      ds =
        Dataset.add(ds, Dataset.new({EX.Subject1, EX.predicate2(), EX.Object4}), graph: EX.Graph)

      assert ds.name == nil
      assert Enum.count(ds) == 5
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object3})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object4, EX.Graph})
    end

    test "a named dataset" do
      ds =
        Dataset.add(
          named_dataset(),
          Dataset.new(
            [
              {EX.Subject1, EX.predicate1(), EX.Object1},
              {EX.Subject1, EX.predicate2(), EX.Object2}
            ],
            name: EX.DS1
          )
        )

      assert ds.name == RDF.iri(EX.DatasetName)
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})

      ds = Dataset.add(ds, Dataset.new({EX.Subject1, EX.predicate2(), EX.Object3}, name: EX.DS2))

      ds =
        Dataset.add(
          ds,
          Dataset.new({EX.Subject1, EX.predicate2(), EX.Object3, EX.Graph}, name: EX.DS2)
        )

      ds =
        Dataset.add(
          ds,
          Dataset.new({EX.Subject1, EX.predicate2(), EX.Object4}, name: EX.DS2),
          graph: EX.Graph
        )

      assert ds.name == RDF.iri(EX.DatasetName)
      assert Enum.count(ds) == 5
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object3})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate2(), EX.Object4, EX.Graph})
    end

    test "a list of descriptions" do
      ds =
        Dataset.add(dataset(), [
          Description.new(EX.Subject1, init: {EX.predicate1(), EX.Object1}),
          Description.new(EX.Subject2, init: {EX.predicate2(), EX.Object2}),
          Description.new(EX.Subject1, init: {EX.predicate3(), EX.Object3})
        ])

      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject2, EX.predicate2(), EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate3(), EX.Object3})

      ds =
        Dataset.add(
          ds,
          [
            Description.new(EX.Subject1, init: {EX.predicate1(), EX.Object1}),
            Description.new(EX.Subject2, init: {EX.predicate2(), EX.Object2}),
            Description.new(EX.Subject1, init: {EX.predicate3(), EX.Object3})
          ],
          graph: EX.Graph
        )

      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject2, EX.predicate2(), EX.Object2, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate3(), EX.Object3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate1(), EX.Object1})
      assert dataset_includes_statement?(ds, {EX.Subject2, EX.predicate2(), EX.Object2})
      assert dataset_includes_statement?(ds, {EX.Subject1, EX.predicate3(), EX.Object3})
    end

    test "a list of graphs" do
      ds =
        Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}])
        |> Dataset.add([
          Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S1, EX.P2, bnode(:foo)}]),
          Graph.new({EX.S1, EX.P2, EX.O3}),
          Graph.new([{EX.S1, EX.P2, EX.O2}, {EX.S2, EX.P2, EX.O2}], name: EX.Graph)
        ])

      assert Enum.count(ds) == 6
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O2, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2, EX.Graph})
    end

    test "lists of descriptions, graphs and datasets without an overwriting graph context" do
      ds =
        Dataset.new([{EX.S1, EX.p(), EX.O}, {EX.S2, EX.p(), EX.O, EX.Graph}])
        |> Dataset.add([
          EX.S1 |> EX.p(bnode(:foo)),
          %{EX.S1 => {EX.p(), EX.O1}},
          EX.S2 |> EX.p(EX.O3) |> RDF.graph(),
          EX.S2 |> EX.p(EX.O4) |> RDF.graph(name: EX.Graph),
          EX.S2 |> EX.p(EX.O5) |> RDF.dataset()
        ])

      assert Dataset.statement_count(ds) == 7
      assert dataset_includes_statement?(ds, {EX.S1, EX.p(), EX.O})
      assert dataset_includes_statement?(ds, {EX.S1, EX.p(), bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S1, EX.p(), EX.O1})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p(), EX.O3})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p(), EX.O5})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p(), EX.O, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p(), EX.O4, EX.Graph})
    end

    test "lists of descriptions, graphs and datasets with an overwriting graph context" do
      ds =
        Dataset.new([{EX.S1, EX.p(), EX.O}, {EX.S2, EX.p(), EX.O, EX.Graph}])
        |> Dataset.add(
          [
            EX.S1 |> EX.p(bnode(:foo)),
            %{EX.S1 => {EX.p(), EX.O1}},
            EX.S2 |> EX.p(EX.O3) |> RDF.graph(),
            EX.S2 |> EX.p(EX.O4) |> RDF.graph(name: EX.Graph),
            EX.S2 |> EX.p(EX.O5) |> RDF.dataset()
          ],
          graph: EX.Graph2
        )

      assert Dataset.statement_count(ds) == 7
      assert dataset_includes_statement?(ds, {EX.S1, EX.p(), EX.O})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p(), EX.O, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S1, EX.p(), bnode(:foo), EX.Graph2})
      assert dataset_includes_statement?(ds, {EX.S1, EX.p(), EX.O1, EX.Graph2})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p(), EX.O3, EX.Graph2})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p(), EX.O4, EX.Graph2})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p(), EX.O5, EX.Graph2})
    end

    test "with a context" do
      context =
        PropertyMap.new(
          p1: EX.p1(),
          p2: EX.p2()
        )

      assert Dataset.add(dataset(), {EX.Subject, :p, 42}, context: [p: EX.predicate()])
             |> dataset_includes_statement?({RDF.iri(EX.Subject), EX.predicate(), literal(42)})

      assert Dataset.add(dataset(), {EX.Subject, :p, 42, EX.Graph}, context: %{p: EX.predicate()})
             |> dataset_includes_statement?(
               {RDF.iri(EX.Subject), EX.predicate(), literal(42), EX.Graph}
             )

      g =
        Dataset.add(
          dataset(),
          [
            {EX.S1, :p1, EX.O1},
            {EX.S2, :p2, [EX.O21, EX.O22]}
          ],
          context: context
        )

      assert Dataset.statement_count(g) == 3
      assert dataset_includes_statement?(g, {EX.S1, EX.p1(), EX.O1})
      assert dataset_includes_statement?(g, {EX.S2, EX.p2(), EX.O21})
      assert dataset_includes_statement?(g, {EX.S2, EX.p2(), EX.O22})

      g =
        Dataset.add(
          dataset(),
          [
            {EX.S1,
             [
               {:p1, EX.O1},
               %{p2: [EX.O2]}
             ]}
          ],
          context: context
        )

      assert Dataset.statement_count(g) == 2
      assert dataset_includes_statement?(g, {EX.S1, EX.p1(), EX.O1})
      assert dataset_includes_statement?(g, {EX.S1, EX.p2(), EX.O2})
    end

    test "duplicates are ignored" do
      ds = Dataset.add(dataset(), {EX.Subject, EX.predicate(), EX.Object, EX.GraphName})
      assert Dataset.add(ds, {EX.Subject, EX.predicate(), EX.Object, EX.GraphName}) == ds
    end

    test "non-coercible statements elements are causing an error" do
      assert_raise RDF.IRI.InvalidError, fn ->
        Dataset.add(
          dataset(),
          {"not a IRI", EX.predicate(), RDF.iri(EX.Object), RDF.iri(EX.GraphName)}
        )
      end

      assert_raise RDF.Literal.InvalidError, fn ->
        Dataset.add(dataset(), {EX.Subject, EX.prop(), self(), nil})
      end

      assert_raise RDF.IRI.InvalidError, fn ->
        Dataset.add(
          dataset(),
          {RDF.iri(EX.Subject), EX.predicate(), RDF.iri(EX.Object), "not a IRI"}
        )
      end

      assert_raise RDF.IRI.InvalidError, fn ->
        Dataset.add(dataset(), {RDF.iri(EX.Subject), EX.predicate(), RDF.iri(EX.Object)},
          graph: "not a IRI"
        )
      end
    end

    test "structs are causing an error" do
      assert_raise FunctionClauseError, fn ->
        Dataset.add(dataset(), Date.utc_today())
      end
    end
  end

  describe "put/3" do
    test "a list of statements without an overwriting graph context" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S2, EX.P2, EX.O2, EX.Graph},
          {EX.S3, EX.P3, EX.O3, EX.Graph}
        ])
        |> Dataset.put([
          {EX.S1, EX.P2, bnode(:foo), nil},
          {EX.S1, EX.P2, EX.O3, EX.Graph},
          {EX.S2, EX.P3, EX.O3, EX.Graph},
          {EX.S3, EX.P3, EX.O3}
        ])

      assert Dataset.statement_count(ds) == 5
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P3, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P3, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P3, EX.O3, EX.Graph})
    end

    test "a list of statements with an overwriting graph context" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S2, EX.P2, EX.O2},
          {EX.S4, EX.P4, EX.O4},
          {EX.S3, EX.P3, EX.O3, EX.Graph}
        ])
        |> Dataset.put(
          [
            {EX.S1, EX.P2, bnode(:foo), nil},
            {EX.S1, EX.P2, EX.O3, EX.Graph},
            {EX.S1, EX.P3, EX.O3},
            {EX.S2, EX.P3, EX.O3},
            {EX.S3, EX.P4, EX.O4, EX.Graph}
          ],
          graph: nil
        )

      assert Dataset.statement_count(ds) == 7
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P3, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P4, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S4, EX.P4, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P3, EX.O3, EX.Graph})

      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S2, EX.P2, EX.O2},
          {EX.S3, EX.P3, EX.O3, EX.Graph}
        ])
        |> Dataset.put(
          [
            {EX.S1, EX.P2, bnode(:foo), nil},
            {EX.S1, EX.P2, EX.O3, EX.Graph},
            {EX.S1, EX.P3, EX.O3},
            {EX.S2, EX.P3, EX.O3},
            {EX.S3, EX.P4, EX.O4, EX.Graph}
          ],
          graph: EX.Graph2
        )

      assert Dataset.statement_count(ds) == 8
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo), EX.Graph2})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O3, EX.Graph2})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O3, EX.Graph2})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P3, EX.O3, EX.Graph2})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P4, EX.O4, EX.Graph2})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P3, EX.O3, EX.Graph})
    end

    test "lists of subject-predications pairs" do
      ds =
        Dataset.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}])
        |> Dataset.put([
          {EX.S1, [{EX.p2(), EX.O2}]},
          {EX.S3, %{EX.p3() => EX.O3}}
        ])

      assert Dataset.statement_count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.S1, EX.p2(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p2(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S3, EX.p3(), EX.O3})
    end

    test "maps" do
      ds =
        Dataset.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}])
        |> Dataset.put(%{
          EX.S1 => [{EX.p2(), EX.O2}],
          EX.S2 => %{EX.p1() => EX.O2},
          EX.S3 => %{EX.p3() => EX.O3}
        })

      assert Dataset.statement_count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.S1, EX.p2(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p1(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S3, EX.p3(), EX.O3})
    end

    test "descriptions" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S1, EX.P3, EX.O3},
          {EX.S2, EX.P2, EX.O2}
        ])
        |> Dataset.put(
          Description.new(EX.S1)
          |> Description.add([{EX.P3, EX.O4}, {EX.P2, bnode(:foo)}])
        )

      assert Dataset.statement_count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2})
    end

    test "an unnamed graph without an overwriting graph context" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S1, EX.P2, EX.O2},
          {EX.S2, EX.P2, EX.O2}
        ])
        |> Dataset.put(
          Graph.new([
            {EX.S1, EX.P3, EX.O4},
            {EX.S1, EX.P2, bnode(:foo)}
          ])
        )

      assert Dataset.statement_count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2})
    end

    test "an unnamed graph with an overwriting graph context" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S1, EX.P2, EX.O2},
          {EX.S2, EX.P2, EX.O2},
          {EX.S3, EX.P3, EX.O3}
        ])
        |> Dataset.put(
          Graph.new([
            {EX.S1, EX.P3, EX.O3},
            {EX.S2, EX.P2, bnode(:foo)}
          ]),
          graph: nil
        )

      assert Dataset.statement_count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.S3, EX.P3, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, bnode(:foo)})

      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S2, EX.P2, EX.O2, EX.Graph},
          {EX.S3, EX.P3, EX.O3, EX.Graph}
        ])
        |> Dataset.put(
          Graph.new([
            {EX.S1, EX.P3, EX.O3},
            {EX.S2, EX.P2, bnode(:foo)}
          ]),
          graph: EX.Graph
        )

      assert Dataset.statement_count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P3, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, bnode(:foo), EX.Graph})
    end

    test "a named graph without an overwriting graph context" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S1, EX.P2, EX.O2, EX.Graph},
          {EX.S2, EX.P2, EX.O2, EX.Graph}
        ])
        |> Dataset.put(
          Graph.new(
            [
              {EX.S1, EX.P3, EX.O4},
              {EX.S1, EX.P2, bnode(:foo)}
            ],
            name: EX.Graph
          )
        )

      assert Dataset.statement_count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo), EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2, EX.Graph})
    end

    test "a named graph with an overwriting graph context" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S1, EX.P2, EX.O2, EX.Graph},
          {EX.S2, EX.P2, EX.O2},
          {EX.S3, EX.P3, EX.O3}
        ])
        |> Dataset.put(
          Graph.new(
            [
              {EX.S1, EX.P3, EX.O3},
              {EX.S2, EX.P3, bnode(:foo)}
            ],
            name: EX.Graph
          ),
          graph: nil
        )

      assert Dataset.statement_count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O2, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P3, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P3, EX.O3})

      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S2, EX.P2, EX.O2, EX.Graph}
        ])
        |> Dataset.put(
          Graph.new(
            [
              {EX.S1, EX.P3, EX.O3},
              {EX.S2, EX.P3, bnode(:foo)}
            ],
            name: EX.Graph2
          ),
          graph: EX.Graph
        )

      assert Dataset.statement_count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P3, bnode(:foo), EX.Graph})
    end

    test "a dataset without an overwriting graph context" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S1, EX.P2, EX.O2, EX.Graph},
          {EX.S2, EX.P2, EX.O2, EX.Graph},
          {EX.S3, EX.P3, EX.O3, EX.Graph2}
        ])
        |> Dataset.put(
          Dataset.new([
            {EX.S1, EX.P3, EX.O4},
            {EX.S2, EX.P3, EX.O4},
            {EX.S1, EX.P1, EX.O1, EX.Graph}
          ])
        )

      assert Dataset.statement_count(ds) == 5
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P3, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P3, EX.O3, EX.Graph2})
    end

    test "a dataset with an overwriting graph context" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S1, EX.P2, EX.O2, EX.Graph},
          {EX.S2, EX.P2, EX.O2, EX.Graph},
          {EX.S3, EX.P3, EX.O3, EX.Graph},
          {EX.S3, EX.P3, EX.O3, EX.Graph2}
        ])
        |> Dataset.put(
          Dataset.new([
            {EX.S1, EX.P3, EX.O4},
            {EX.S2, EX.P3, EX.O4},
            {EX.S1, EX.P1, EX.O1, EX.Graph}
          ]),
          graph: EX.Graph
        )

      assert Dataset.statement_count(ds) == 6
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P3, EX.O4, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P3, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P3, EX.O3, EX.Graph2})
    end

    test "lists of descriptions, graphs and datasets" do
      ds =
        Dataset.new([{EX.S1, EX.p(), EX.O}, {EX.S2, EX.p(), EX.O, EX.Graph}])
        |> Dataset.put([
          EX.S1 |> EX.p2(bnode(:foo)),
          EX.S1 |> EX.p2("bar"),
          %{EX.S1 => {EX.p2(), EX.O1}},
          EX.S2 |> EX.p2(EX.O3) |> RDF.graph(),
          EX.S2 |> EX.p2(EX.O4) |> RDF.graph(name: EX.Graph),
          EX.S2 |> EX.p2(EX.O5) |> RDF.dataset()
        ])

      assert Dataset.statement_count(ds) == 6
      assert dataset_includes_statement?(ds, {EX.S1, EX.p2(), bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S1, EX.p2(), ~L"bar"})
      assert dataset_includes_statement?(ds, {EX.S1, EX.p2(), EX.O1})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p2(), EX.O3})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p2(), EX.O4, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p2(), EX.O5})
    end

    test "with a context" do
      ds =
        Dataset.new()
        |> Dataset.put({EX.S, :p, EX.O}, context: [p: EX.p()])

      assert dataset_includes_statement?(ds, {EX.S, EX.p(), EX.O})
    end

    test "simultaneous use of the different forms to address the default context" do
      ds =
        Dataset.put(dataset(), [
          {EX.S, EX.P, EX.O1},
          {EX.S, EX.P, EX.O2, nil}
        ])

      assert Dataset.statement_count(ds) == 2
      assert dataset_includes_statement?(ds, {EX.S, EX.P, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S, EX.P, EX.O2})
    end

    test "structs are causing an error" do
      assert_raise FunctionClauseError, fn ->
        Dataset.put(dataset(), Date.utc_today())
      end
    end
  end

  describe "put_graph/3" do
    test "statements without an overwriting graph context" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S2, EX.P2, EX.O2, EX.Graph},
          {EX.S3, EX.P3, EX.O3, EX.Graph}
        ])
        |> Dataset.put_graph([
          {EX.S1, EX.P2, bnode(:foo), nil},
          {EX.S1, EX.P2, EX.O3, EX.Graph},
          {EX.S2, EX.P3, EX.O3, EX.Graph},
          {EX.S3, EX.P3, EX.O3}
        ])

      assert Dataset.statement_count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P3, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P3, EX.O3})

      ds =
        Dataset.new([{EX.S1, EX.p1(), EX.O1}, {EX.S4, EX.p2(), EX.O2}])
        |> Dataset.put_graph(%{
          EX.S1 => [{EX.p2(), EX.O2}],
          EX.S2 => %{EX.p1() => EX.O2},
          EX.S3 => %{EX.p3() => EX.O3}
        })

      assert Dataset.statement_count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.S1, EX.p2(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p1(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S3, EX.p3(), EX.O3})
    end

    test "statements with an overwriting graph context" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S2, EX.P2, EX.O2},
          {EX.S4, EX.P4, EX.O4},
          {EX.S3, EX.P3, EX.O3, EX.Graph}
        ])
        |> Dataset.put_graph(
          [
            {EX.S1, EX.P2, bnode(:foo), nil},
            {EX.S1, EX.P2, EX.O3, EX.Graph},
            {EX.S1, EX.P3, EX.O3},
            {EX.S2, EX.P3, EX.O3},
            {EX.S3, EX.P4, EX.O4, EX.Graph}
          ],
          graph: nil
        )

      assert Dataset.statement_count(ds) == 6
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P3, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P4, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P3, EX.O3, EX.Graph})

      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S2, EX.P2, EX.O2},
          {EX.S3, EX.P3, EX.O3, EX.Graph}
        ])
        |> Dataset.put_graph(
          [
            {EX.S1, EX.P2, bnode(:foo), nil},
            {EX.S1, EX.P2, EX.O3, EX.Graph},
            {EX.S1, EX.P3, EX.O3},
            {EX.S2, EX.P3, EX.O3},
            {EX.S3, EX.P4, EX.O4, EX.Graph}
          ],
          graph: EX.Graph2
        )

      assert Dataset.statement_count(ds) == 8
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo), EX.Graph2})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O3, EX.Graph2})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O3, EX.Graph2})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P3, EX.O3, EX.Graph2})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P4, EX.O4, EX.Graph2})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P3, EX.O3, EX.Graph})
    end

    test "an unnamed graph without an overwriting graph context" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S1, EX.P2, EX.O2},
          {EX.S2, EX.P2, EX.O2}
        ])
        |> Dataset.put_graph(
          Graph.new([
            {EX.S1, EX.P3, EX.O4},
            {EX.S1, EX.P2, bnode(:foo)}
          ])
        )

      assert Dataset.statement_count(ds) == 2
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
    end

    test "an unnamed graph with an overwriting graph context" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S1, EX.P2, EX.O2},
          {EX.S2, EX.P2, EX.O2},
          {EX.S3, EX.P3, EX.O3}
        ])
        |> Dataset.put_graph(
          Graph.new([
            {EX.S1, EX.P3, EX.O3},
            {EX.S2, EX.P2, bnode(:foo)}
          ]),
          graph: nil
        )

      assert Dataset.statement_count(ds) == 2
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, bnode(:foo)})

      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S2, EX.P2, EX.O2, EX.Graph},
          {EX.S3, EX.P3, EX.O3, EX.Graph}
        ])
        |> Dataset.put_graph(
          Graph.new([
            {EX.S1, EX.P3, EX.O3},
            {EX.S2, EX.P2, bnode(:foo)}
          ]),
          graph: EX.Graph
        )

      assert Dataset.statement_count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, bnode(:foo), EX.Graph})
    end

    test "a named graph without an overwriting graph context" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S1, EX.P2, EX.O2, EX.Graph},
          {EX.S2, EX.P2, EX.O2, EX.Graph}
        ])
        |> Dataset.put_graph(
          Graph.new(
            [
              {EX.S1, EX.P3, EX.O4},
              {EX.S1, EX.P2, bnode(:foo)}
            ],
            name: EX.Graph
          )
        )

      assert Dataset.statement_count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo), EX.Graph})
    end

    test "a named graph with an overwriting graph context" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S1, EX.P2, EX.O2, EX.Graph},
          {EX.S2, EX.P2, EX.O2},
          {EX.S3, EX.P3, EX.O3}
        ])
        |> Dataset.put_graph(
          Graph.new(
            [
              {EX.S1, EX.P3, EX.O3},
              {EX.S2, EX.P3, bnode(:foo)}
            ],
            name: EX.Graph
          ),
          graph: nil
        )

      assert Dataset.statement_count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O2, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P3, bnode(:foo)})

      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S2, EX.P2, EX.O2, EX.Graph}
        ])
        |> Dataset.put_graph(
          Graph.new(
            [
              {EX.S1, EX.P3, EX.O3},
              {EX.S2, EX.P3, bnode(:foo)}
            ],
            name: EX.Graph2
          ),
          graph: EX.Graph
        )

      assert Dataset.statement_count(ds) == 3
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P3, bnode(:foo), EX.Graph})
    end

    test "a dataset without an overwriting graph context" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S1, EX.P2, EX.O2, EX.Graph},
          {EX.S2, EX.P2, EX.O2, EX.Graph},
          {EX.S3, EX.P3, EX.O3, EX.Graph2}
        ])
        |> Dataset.put_graph(
          Dataset.new([
            {EX.S1, EX.P3, EX.O4},
            {EX.S2, EX.P3, EX.O4},
            {EX.S1, EX.P1, EX.O1, EX.Graph}
          ])
        )

      assert Dataset.statement_count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P3, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P3, EX.O3, EX.Graph2})
    end

    test "a dataset with an overwriting graph context" do
      ds =
        Dataset.new([
          {EX.S1, EX.P1, EX.O1},
          {EX.S1, EX.P2, EX.O2, EX.Graph},
          {EX.S2, EX.P2, EX.O2, EX.Graph},
          {EX.S3, EX.P3, EX.O3, EX.Graph},
          {EX.S3, EX.P3, EX.O3, EX.Graph2}
        ])
        |> Dataset.put_graph(
          Dataset.new([
            {EX.S1, EX.P3, EX.O4},
            {EX.S2, EX.P3, EX.O4},
            {EX.S1, EX.P1, EX.O1, EX.Graph}
          ]),
          graph: EX.Graph
        )

      assert Dataset.statement_count(ds) == 5
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P3, EX.O4, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S3, EX.P3, EX.O3, EX.Graph2})
    end

    test "lists of descriptions, graphs and datasets" do
      ds =
        Dataset.new([{EX.S1, EX.p(), EX.O}, {EX.S2, EX.p(), EX.O, EX.Graph}])
        |> Dataset.put_graph([
          EX.S1 |> EX.p2(bnode(:foo)),
          EX.S1 |> EX.p2("bar"),
          %{EX.S1 => {EX.p2(), EX.O1}},
          EX.S2 |> EX.p2(EX.O3) |> RDF.graph(),
          EX.S2 |> EX.p2(EX.O4) |> RDF.graph(name: EX.Graph),
          EX.S2 |> EX.p2(EX.O5) |> RDF.dataset()
        ])

      assert Dataset.statement_count(ds) == 6
      assert dataset_includes_statement?(ds, {EX.S1, EX.p2(), bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S1, EX.p2(), ~L"bar"})
      assert dataset_includes_statement?(ds, {EX.S1, EX.p2(), EX.O1})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p2(), EX.O3})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p2(), EX.O4, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p2(), EX.O5})
    end

    test "with a context" do
      ds =
        Dataset.new()
        |> Dataset.put_graph({EX.S, :p, EX.O}, context: [p: EX.p()])

      assert dataset_includes_statement?(ds, {EX.S, EX.p(), EX.O})
    end

    test "simultaneous use of the different forms to address the default context" do
      ds =
        Dataset.put_graph(dataset(), [
          {EX.S, EX.P, EX.O1},
          {EX.S, EX.P, EX.O2, nil}
        ])

      assert Dataset.statement_count(ds) == 2
      assert dataset_includes_statement?(ds, {EX.S, EX.P, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S, EX.P, EX.O2})
    end

    test "structs are causing an error" do
      assert_raise FunctionClauseError, fn ->
        Dataset.put_graph(dataset(), Date.utc_today())
      end
    end
  end

  describe "put_properties/3" do
    test "a list of statements without an overwriting graph context" do
      ds =
        Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2, EX.Graph}])
        |> Dataset.put_properties([
          {EX.S1, EX.P2, EX.O3, EX.Graph},
          {EX.S1, EX.P2, bnode(:foo), nil},
          {EX.S2, EX.P2, EX.O3, EX.Graph},
          {EX.S2, EX.P2, EX.O4, EX.Graph}
        ])

      assert Dataset.statement_count(ds) == 5
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O4, EX.Graph})
    end

    test "a list of statements with an overwriting graph context" do
      ds =
        Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2, EX.Graph}])
        |> Dataset.put_properties(
          [
            {EX.S1, EX.P1, EX.O3, EX.Graph},
            {EX.S1, EX.P2, bnode(:foo), nil},
            {EX.S2, EX.P2, EX.O3, EX.Graph},
            {EX.S2, EX.P2, EX.O4}
          ],
          graph: nil
        )

      assert Dataset.statement_count(ds) == 5
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O3})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2, EX.Graph})

      ds =
        Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2, EX.Graph}])
        |> Dataset.put_properties(
          [
            {EX.S1, EX.P1, EX.O3},
            {EX.S1, EX.P1, EX.O4, EX.Graph},
            {EX.S1, EX.P2, bnode(:foo), nil},
            {EX.S2, EX.P2, EX.O3, EX.Graph},
            {EX.S2, EX.P2, EX.O4}
          ],
          graph: EX.Graph
        )

      assert Dataset.statement_count(ds) == 6
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O4, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo), EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O3, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O4, EX.Graph})
    end

    test "lists of subject-predications pairs" do
      ds =
        Dataset.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}])
        |> Dataset.put_properties([
          {EX.S1, [{EX.p1(), EX.O2}]},
          {EX.S2, %{EX.p1() => EX.O2}},
          {EX.S3, %{EX.p3() => EX.O3}}
        ])

      assert Dataset.statement_count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.S1, EX.p1(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p2(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p1(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S3, EX.p3(), EX.O3})
    end

    test "maps" do
      ds =
        Dataset.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}])
        |> Dataset.put_properties(%{
          EX.S1 => [{EX.p1(), EX.O2}],
          EX.S2 => %{EX.p1() => EX.O2},
          EX.S3 => %{EX.p3() => EX.O3}
        })

      assert Dataset.statement_count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.S1, EX.p1(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p2(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p1(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S3, EX.p3(), EX.O3})
    end

    test "descriptions" do
      ds =
        Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}, {EX.S1, EX.P3, EX.O3}])
        |> Dataset.put_properties(
          Description.new(EX.S1)
          |> Description.add([{EX.P3, EX.O4}, {EX.P2, bnode(:foo)}])
        )

      assert Dataset.statement_count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2})
    end

    test "an unnamed graph" do
      ds =
        Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}, {EX.S1, EX.P3, EX.O3}])
        |> Dataset.put_properties(Graph.new([{EX.S1, EX.P3, EX.O4}, {EX.S1, EX.P2, bnode(:foo)}]))

      assert Dataset.statement_count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2})
    end

    test "a named graph" do
      ds =
        Dataset.new(
          Graph.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}, {EX.S1, EX.P3, EX.O3}],
            name: EX.GraphName
          )
        )
        |> Dataset.put_properties(
          Graph.new([{EX.S1, EX.P3, EX.O4}, {EX.S1, EX.P2, bnode(:foo)}]),
          graph: EX.GraphName
        )

      assert Dataset.statement_count(ds) == 4
      assert dataset_includes_statement?(ds, {EX.S1, EX.P1, EX.O1, EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P3, EX.O4, EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.S1, EX.P2, bnode(:foo), EX.GraphName})
      assert dataset_includes_statement?(ds, {EX.S2, EX.P2, EX.O2, EX.GraphName})
    end

    test "lists of descriptions, graphs and datasets" do
      ds =
        Dataset.new([{EX.S1, EX.p(), EX.O}, {EX.S2, EX.p(), EX.O, EX.Graph}])
        |> Dataset.put_properties([
          EX.S1 |> EX.p(bnode(:foo)),
          EX.S1 |> EX.p("bar"),
          %{EX.S1 => {EX.p(), EX.O1}},
          EX.S2 |> EX.p(EX.O3) |> RDF.graph(),
          EX.S2 |> EX.p(EX.O4) |> RDF.graph(name: EX.Graph),
          EX.S2 |> EX.p(EX.O5) |> RDF.dataset()
        ])

      assert Dataset.statement_count(ds) == 6
      assert dataset_includes_statement?(ds, {EX.S1, EX.p(), bnode(:foo)})
      assert dataset_includes_statement?(ds, {EX.S1, EX.p(), ~L"bar"})
      assert dataset_includes_statement?(ds, {EX.S1, EX.p(), EX.O1})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p(), EX.O3})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p(), EX.O4, EX.Graph})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p(), EX.O5})
    end

    test "with a context" do
      ds =
        Dataset.new()
        |> Dataset.put_properties({EX.S, :p, EX.O}, context: [p: EX.p()])

      assert dataset_includes_statement?(ds, {EX.S, EX.p(), EX.O})
    end

    test "simultaneous use of the different forms to address the default context" do
      ds =
        Dataset.put_properties(dataset(), [
          {EX.S, EX.P, EX.O1},
          {EX.S, EX.P, EX.O2, nil}
        ])

      assert Dataset.statement_count(ds) == 2
      assert dataset_includes_statement?(ds, {EX.S, EX.P, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S, EX.P, EX.O2})
    end

    test "structs are causing an error" do
      assert_raise FunctionClauseError, fn ->
        Dataset.put_properties(dataset(), Date.utc_today())
      end
    end
  end

  describe "update/4" do
    test "a graph returned from the update function replaces the old graph" do
      old_graph = Graph.new({EX.S2, EX.p2(), EX.O3})
      new_graph = Graph.new({EX.S2, EX.p(), EX.O})

      assert Dataset.new([
               {EX.S1, EX.p1(), [EX.O1, EX.O2], EX.AnotherGraph},
               old_graph
             ])
             |> Dataset.update(nil, fn ^old_graph -> new_graph end) ==
               Dataset.new([
                 {EX.S1, EX.p1(), [EX.O1, EX.O2], EX.AnotherGraph},
                 new_graph
               ])

      old_graph = Graph.new({EX.S2, EX.p2(), EX.O3}, name: EX.Graph)
      new_graph = Graph.new({EX.S2, EX.p(), EX.O}, name: EX.Graph)

      assert Dataset.new([
               {EX.S1, EX.p1(), [EX.O1, EX.O2], EX.AnotherGraph},
               old_graph
             ])
             |> Dataset.update(EX.Graph, fn ^old_graph -> new_graph end) ==
               Dataset.new([
                 {EX.S1, EX.p1(), [EX.O1, EX.O2], EX.AnotherGraph},
                 new_graph
               ])
    end

    test "a graph with another graph name returned from the update function replaces the old graph" do
      old_graph = Graph.new({EX.S2, EX.p2(), EX.O3}, name: EX.Graph)
      new_graph = Graph.new({EX.S2, EX.p(), EX.O}, name: EX.Graph)

      assert Dataset.new([
               {EX.S1, EX.p1(), [EX.O1, EX.O2], EX.AnotherGraph},
               old_graph
             ])
             |> Dataset.update(EX.Graph, fn ^old_graph ->
               Graph.new({EX.S2, EX.p(), EX.O}, name: EX.Ignored)
             end) ==
               Dataset.new([
                 {EX.S1, EX.p1(), [EX.O1, EX.O2], EX.AnotherGraph},
                 new_graph
               ])

      assert Dataset.new([
               {EX.S1, EX.p1(), [EX.O1, EX.O2], EX.AnotherGraph},
               old_graph
             ])
             |> Dataset.update(EX.Graph, fn ^old_graph ->
               Graph.new({EX.S2, EX.p(), EX.O}, name: nil)
             end) ==
               Dataset.new([
                 {EX.S1, EX.p1(), [EX.O1, EX.O2], EX.AnotherGraph},
                 new_graph
               ])
    end

    test "a value returned from the update function becomes new coerced graph" do
      old_graph = Graph.new({EX.S2, EX.p2(), EX.O3}, name: EX.Graph)
      new_graph = Graph.new({EX.S2, EX.p(), EX.O}, name: EX.Graph)

      assert Dataset.new([
               {EX.S1, EX.p1(), [EX.O1, EX.O2], EX.AnotherGraph},
               old_graph
             ])
             |> Dataset.update(EX.Graph, fn ^old_graph -> Graph.triples(new_graph) end) ==
               Dataset.new([
                 {EX.S1, EX.p1(), [EX.O1, EX.O2], EX.AnotherGraph},
                 new_graph
               ])
    end

    test "returning nil from the update function causes a removal of the graph" do
      assert Dataset.new({EX.S, EX.p(), EX.O, EX.Graph})
             |> Dataset.update(EX.Graph, fn _ -> nil end) ==
               Dataset.new()
    end

    test "when the graph is not present the initial value is added and the update function is not called" do
      fun = fn _ -> raise "should not be called" end

      assert Dataset.new()
             |> Dataset.update(EX.Graph, {EX.S, EX.P, EX.O}, fun) ==
               Dataset.new({EX.S, EX.P, EX.O, EX.Graph})

      assert Dataset.new()
             |> Dataset.update(nil, {EX.S, EX.P, EX.O}, fun) ==
               Dataset.new({EX.S, EX.P, EX.O})

      assert Dataset.new()
             |> Dataset.update(EX.Graph, fun) ==
               Dataset.new()
    end
  end

  describe "delete" do
    setup do
      {:ok,
       dataset1: Dataset.new({EX.S1, EX.p1(), EX.O1}),
       dataset2:
         Dataset.new([
           {EX.S1, EX.p1(), EX.O1},
           {EX.S2, EX.p2(), EX.O2, EX.Graph}
         ]),
       dataset3:
         Dataset.new([
           {EX.S1, EX.p1(), EX.O1},
           {EX.S2, EX.p2(), [EX.O1, EX.O2], EX.Graph1},
           {EX.S3, EX.p3(), [~B<foo>, ~L"bar"], EX.Graph2}
         ])}
    end

    test "a single statement",
         %{dataset1: dataset1, dataset2: dataset2, dataset3: dataset3} do
      assert Dataset.delete(Dataset.new(), {EX.S, EX.p(), EX.O}) == Dataset.new()
      assert Dataset.delete(dataset1, {EX.S1, EX.p1(), EX.O1}) == Dataset.new()
      assert Dataset.delete(dataset2, {EX.S2, EX.p2(), EX.O2, EX.Graph}) == dataset1

      assert Dataset.delete(dataset2, {EX.S1, EX.p1(), EX.O1}) ==
               Dataset.new({EX.S2, EX.p2(), EX.O2, EX.Graph})

      assert Dataset.delete(dataset3, {EX.S2, EX.p2(), EX.O1, EX.Graph1}) ==
               Dataset.new([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S2, EX.p2(), EX.O2, EX.Graph1},
                 {EX.S3, EX.p3(), [~B<foo>, ~L"bar"], EX.Graph2}
               ])

      assert Dataset.delete(dataset3, {EX.S2, EX.p2(), [EX.O1, EX.O2], EX.Graph1}) ==
               Dataset.new([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S3, EX.p3(), [~B<foo>, ~L"bar"], EX.Graph2}
               ])

      assert Dataset.delete(dataset3, {EX.S2, EX.p2(), [EX.O1, EX.O2]}, graph: EX.Graph1) ==
               Dataset.new([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S3, EX.p3(), [~B<foo>, ~L"bar"], EX.Graph2}
               ])
    end

    test "multiple statements with a list of triples",
         %{dataset1: dataset1, dataset2: dataset2, dataset3: dataset3} do
      assert Dataset.delete(dataset1, [{EX.S1, EX.p1(), EX.O1}, {EX.S1, EX.p1(), EX.O2}]) ==
               Dataset.new()

      assert Dataset.delete(dataset2, [{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2, EX.Graph}]) ==
               Dataset.new()

      assert Dataset.delete(dataset3, [
               {EX.S1, EX.p1(), EX.O1},
               {EX.S2, EX.p2(), [EX.O1, EX.O2, EX.O3], EX.Graph1},
               {EX.S3, EX.p3(), ~B<foo>, EX.Graph2}
             ]) == Dataset.new({EX.S3, EX.p3(), ~L"bar", EX.Graph2})
    end

    test "multiple statements with a map",
         %{dataset1: dataset1, dataset2: dataset2} do
      assert Dataset.delete(dataset1, %{EX.S1 => {EX.p1(), EX.O1}}) ==
               Dataset.new()

      assert Dataset.delete(
               dataset1,
               %{EX.S1 => {EX.p1(), EX.O1}},
               graph: EX.Graph
             ) ==
               dataset1

      assert Dataset.delete(
               dataset2,
               %{EX.S2 => %{EX.p2() => EX.O2}},
               graph: EX.Graph
             ) ==
               dataset1

      assert Dataset.delete(dataset2, %{EX.S1 => %{EX.p1() => EX.O1}}) ==
               Dataset.new({EX.S2, EX.p2(), EX.O2, EX.Graph})
    end

    test "multiple statements with a description",
         %{dataset1: dataset1, dataset2: dataset2} do
      assert Dataset.delete(dataset1, Description.new(EX.S1, init: {EX.p1(), EX.O1})) ==
               Dataset.new()

      assert Dataset.delete(dataset1, Description.new(EX.S1, init: {EX.p1(), EX.O1}),
               graph: EX.Graph
             ) ==
               dataset1

      assert Dataset.delete(dataset2, Description.new(EX.S2, init: {EX.p2(), EX.O2}),
               graph: EX.Graph
             ) ==
               dataset1

      assert Dataset.delete(dataset2, Description.new(EX.S1, init: {EX.p1(), EX.O1})) ==
               Dataset.new({EX.S2, EX.p2(), EX.O2, EX.Graph})
    end

    test "multiple statements with a graph",
         %{dataset1: dataset1, dataset2: dataset2, dataset3: dataset3} do
      assert Dataset.delete(dataset1, Graph.new({EX.S1, EX.p1(), EX.O1})) == Dataset.new()

      assert Dataset.delete(dataset2, Graph.new({EX.S1, EX.p1(), EX.O1})) ==
               Dataset.new({EX.S2, EX.p2(), EX.O2, EX.Graph})

      assert Dataset.delete(dataset2, Graph.new({EX.S2, EX.p2(), EX.O2}, name: EX.Graph)) ==
               dataset1

      assert Dataset.delete(dataset2, Graph.new({EX.S2, EX.p2(), EX.O2}, name: EX.Graph)) ==
               dataset1

      assert Dataset.delete(dataset2, Graph.new({EX.S2, EX.p2(), EX.O2}), graph: EX.Graph) ==
               dataset1

      assert Dataset.delete(dataset2, Graph.new({EX.S2, EX.p2(), EX.O2}), graph: EX.Graph) ==
               dataset1

      assert Dataset.delete(
               dataset3,
               Graph.new([
                 {EX.S1, EX.p1(), [EX.O1, EX.O2]},
                 {EX.S2, EX.p2(), EX.O3},
                 {EX.S3, EX.p3(), ~B<foo>}
               ])
             ) ==
               Dataset.new([
                 {EX.S2, EX.p2(), [EX.O1, EX.O2], EX.Graph1},
                 {EX.S3, EX.p3(), [~B<foo>, ~L"bar"], EX.Graph2}
               ])

      assert Dataset.delete(
               dataset3,
               Graph.new(
                 [
                   {EX.S1, EX.p1(), [EX.O1, EX.O2]},
                   {EX.S2, EX.p2(), EX.O3},
                   {EX.S3, EX.p3(), ~B<foo>}
                 ],
                 name: EX.Graph2
               )
             ) ==
               Dataset.new([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S2, EX.p2(), [EX.O1, EX.O2], EX.Graph1},
                 {EX.S3, EX.p3(), [~L"bar"], EX.Graph2}
               ])

      assert Dataset.delete(dataset3, Graph.new({EX.S3, EX.p3(), ~B<foo>}), graph: EX.Graph2) ==
               Dataset.new([
                 {EX.S1, EX.p1(), EX.O1},
                 {EX.S2, EX.p2(), [EX.O1, EX.O2], EX.Graph1},
                 {EX.S3, EX.p3(), ~L"bar", EX.Graph2}
               ])
    end

    test "multiple statements with a dataset",
         %{dataset1: dataset1, dataset2: dataset2} do
      assert Dataset.delete(dataset1, dataset1) == Dataset.new()
      assert Dataset.delete(dataset1, dataset2) == Dataset.new()
      assert Dataset.delete(dataset2, dataset1) == Dataset.new({EX.S2, EX.p2(), EX.O2, EX.Graph})
    end

    test "with a context", %{dataset2: dataset2} do
      assert dataset2
             |> Dataset.delete(%{EX.S2 => %{p2: EX.O2}}, graph: EX.Graph, context: [p2: EX.p2()])
             |> Dataset.delete([{EX.S1, [p1: EX.O1]}], context: [p1: EX.p1()]) ==
               Dataset.new()
    end

    test "structs are causing an error" do
      assert_raise FunctionClauseError, fn ->
        Dataset.delete(dataset(), Date.utc_today())
      end
    end
  end

  describe "delete_graph" do
    setup do
      {:ok,
       dataset1: Dataset.new({EX.S1, EX.p1(), EX.O1}),
       dataset2:
         Dataset.new([
           {EX.S1, EX.p1(), EX.O1},
           {EX.S2, EX.p2(), EX.O2, EX.Graph}
         ]),
       dataset3:
         Dataset.new([
           {EX.S1, EX.p1(), EX.O1},
           {EX.S2, EX.p2(), EX.O2, EX.Graph1},
           {EX.S3, EX.p3(), EX.O3, EX.Graph2}
         ])}
    end

    test "the default graph", %{dataset1: dataset1, dataset2: dataset2} do
      assert Dataset.delete_graph(dataset1, nil) == Dataset.new()
      assert Dataset.delete_graph(dataset2, nil) == Dataset.new({EX.S2, EX.p2(), EX.O2, EX.Graph})
    end

    test "delete_default_graph", %{dataset1: dataset1, dataset2: dataset2} do
      assert Dataset.delete_default_graph(dataset1) == Dataset.new()

      assert Dataset.delete_default_graph(dataset2) ==
               Dataset.new({EX.S2, EX.p2(), EX.O2, EX.Graph})
    end

    test "a single graph", %{dataset1: dataset1, dataset2: dataset2} do
      assert Dataset.delete_graph(dataset1, EX.Graph) == dataset1
      assert Dataset.delete_graph(dataset2, EX.Graph) == dataset1
    end

    test "a list of graphs", %{dataset1: dataset1, dataset3: dataset3} do
      assert Dataset.delete_graph(dataset3, [EX.Graph1, EX.Graph2]) == dataset1
      assert Dataset.delete_graph(dataset3, [EX.Graph1, EX.Graph2, EX.Graph3]) == dataset1
      assert Dataset.delete_graph(dataset3, [EX.Graph1, EX.Graph2, nil]) == Dataset.new()
    end
  end

  test "pop" do
    assert Dataset.pop(Dataset.new()) == {nil, Dataset.new()}

    {quad, dataset} = Dataset.new({EX.S, EX.p(), EX.O, EX.Graph}) |> Dataset.pop()
    assert quad == {RDF.iri(EX.S), RDF.iri(EX.p()), RDF.iri(EX.O), RDF.iri(EX.Graph)}
    assert Enum.empty?(dataset.graphs)

    {{subject, predicate, object, _}, dataset} =
      Dataset.new([{EX.S, EX.p(), EX.O, EX.Graph}, {EX.S, EX.p(), EX.O}])
      |> Dataset.pop()

    assert {subject, predicate, object} == {RDF.iri(EX.S), RDF.iri(EX.p()), RDF.iri(EX.O)}
    assert Enum.count(dataset.graphs) == 1

    {{subject, _, _, graph_context}, dataset} =
      Dataset.new([{EX.S, EX.p(), EX.O1, EX.Graph}, {EX.S, EX.p(), EX.O2, EX.Graph}])
      |> Dataset.pop()

    assert subject == RDF.iri(EX.S)
    assert graph_context == RDF.iri(EX.Graph)
    assert Enum.count(dataset.graphs) == 1
  end

  describe "intersection/2" do
    test "with dataset" do
      dataset =
        Dataset.new([
          {EX.S1, EX.p(), [EX.O1, EX.O2]},
          {EX.S2, EX.p(), [EX.O1, EX.O2], EX.Graph}
        ])

      assert Dataset.intersection(dataset, dataset) == dataset

      assert Dataset.intersection(
               dataset,
               Dataset.new([
                 {EX.S1, EX.p(), [EX.O2, EX.O3]},
                 {EX.S2, EX.p(), [EX.O2, EX.O3], EX.Graph}
               ])
             ) ==
               Dataset.new([
                 {EX.S1, EX.p(), [EX.O2]},
                 {EX.S2, EX.p(), [EX.O2], EX.Graph}
               ])

      assert Dataset.intersection(
               dataset,
               Dataset.new([
                 {EX.Other, EX.p(), EX.O1},
                 {EX.S1, EX.p(), [EX.O2], EX.Graph}
               ])
             ) ==
               Dataset.new()
    end

    test "with graph" do
      dataset =
        Dataset.new([
          {EX.S1, EX.p(), [EX.O1, EX.O2]},
          {EX.S2, EX.p(), [EX.O1, EX.O2], EX.Graph}
        ])

      assert Dataset.intersection(dataset, Dataset.default_graph(dataset)) ==
               dataset |> Dataset.default_graph() |> Dataset.new()

      assert Dataset.intersection(dataset, Dataset.graph(dataset, EX.Graph)) ==
               dataset |> Dataset.graph(EX.Graph) |> Dataset.new()

      assert Dataset.intersection(
               dataset,
               Graph.new({EX.S1, EX.p(), [EX.O2, EX.O3]})
             ) ==
               Dataset.new({EX.S1, EX.p(), EX.O2})

      assert Dataset.intersection(
               dataset,
               Graph.new({EX.S2, EX.p(), [EX.O2, EX.O3]}, name: EX.Graph)
             ) ==
               Dataset.new({EX.S2, EX.p(), EX.O2, EX.Graph})

      assert Dataset.intersection(dataset, Graph.new({EX.S2, EX.p(), EX.O1})) ==
               Dataset.new()
    end

    test "with description" do
      dataset =
        Dataset.new([
          {EX.S1, EX.p(), [EX.O1, EX.O2]},
          {EX.S2, EX.p(), [EX.O1, EX.O2], EX.Graph}
        ])

      assert Dataset.intersection(dataset, EX.S1 |> EX.p([EX.O2, EX.O3])) ==
               Dataset.new(EX.S1 |> EX.p(EX.O2))

      assert Dataset.intersection(dataset, EX.S2 |> EX.p([EX.O2, EX.O3])) ==
               Dataset.new()
    end

    test "with coercible data" do
      dataset =
        Dataset.new([
          {EX.S1, EX.p(), [EX.O1, EX.O2]},
          {EX.S2, EX.p(), [EX.O1, EX.O2], EX.Graph}
        ])

      assert Dataset.intersection(dataset, Dataset.statements(dataset)) ==
               dataset

      assert Dataset.intersection(dataset, {EX.S1, EX.p(), [EX.O2, EX.O3]}) ==
               Dataset.new(EX.S1 |> EX.p(EX.O2))

      assert Dataset.intersection(dataset, {EX.S2, EX.p(), [EX.O2, EX.O3], EX.Graph}) ==
               Dataset.new({EX.S2, EX.p(), EX.O2, EX.Graph})

      assert Dataset.intersection(dataset, {EX.S2, EX.p(), [EX.O2, EX.O3]}) ==
               Dataset.new()
    end
  end

  test "statement_count/1" do
    assert Dataset.statement_count(dataset()) == 0
    assert Dataset.statement_count(Dataset.new(statement())) == 1
  end

  test "empty?/1" do
    assert Dataset.empty?(dataset()) == true
    assert Dataset.empty?(Dataset.new(statement())) == false
    assert Dataset.empty?(Dataset.new(graph())) == true
  end

  describe "include?/3" do
    test "valid cases" do
      dataset =
        Dataset.new([
          {EX.S1, EX.p(), EX.O1},
          {EX.S2, EX.p(), EX.O2, EX.Graph}
        ])

      assert Dataset.include?(dataset, {EX.S1, EX.p(), EX.O1})
      refute Dataset.include?(dataset, {EX.S2, EX.p(), EX.O2})
      assert Dataset.include?(dataset, {EX.S2, EX.p(), EX.O2, EX.Graph})
      assert Dataset.include?(dataset, {EX.S2, EX.p(), EX.O2}, graph: EX.Graph)

      assert Dataset.include?(dataset, [{EX.S1, EX.p(), EX.O1}])
      assert Dataset.include?(dataset, [{EX.S2, EX.p(), EX.O2}], graph: EX.Graph)

      assert Dataset.include?(dataset, [
               {EX.S1, EX.p(), EX.O1},
               {EX.S2, EX.p(), EX.O2, EX.Graph}
             ])

      refute Dataset.include?(dataset, [
               {EX.S1, EX.p(), EX.O1},
               {EX.S2, EX.p(), EX.O2}
             ])

      assert Dataset.include?(dataset, EX.S1 |> EX.p(EX.O1))
      refute Dataset.include?(dataset, EX.S2 |> EX.p(EX.O2))
      assert Dataset.include?(dataset, EX.p(EX.S2, EX.O2), graph: EX.Graph)
      assert Dataset.include?(dataset, Graph.new(EX.S1 |> EX.p(EX.O1)))
      assert Dataset.include?(dataset, dataset)

      assert Dataset.include?(
               dataset,
               [
                 {EX.S1, :p, EX.O1},
                 {EX.S2, :p, EX.O2, EX.Graph}
               ],
               context: [p: EX.p()]
             )
    end

    test "structs are causing an error" do
      assert_raise FunctionClauseError, fn ->
        Dataset.include?(dataset(), Date.utc_today())
      end
    end
  end

  test "values/1" do
    assert Dataset.new() |> Dataset.values() == %{}

    assert Dataset.new([{EX.s1(), EX.p(), EX.o1()}, {EX.s2(), EX.p(), EX.o2(), EX.graph()}])
           |> Dataset.values() ==
             %{
               nil => %{
                 RDF.Term.value(EX.s1()) => %{RDF.Term.value(EX.p()) => [RDF.Term.value(EX.o1())]}
               },
               RDF.Term.value(EX.graph()) => %{
                 RDF.Term.value(EX.s2()) => %{RDF.Term.value(EX.p()) => [RDF.Term.value(EX.o2())]}
               }
             }
  end

  test "values/2" do
    expected_result = %{
      nil => %{
        RDF.Term.value(EX.s1()) => %{p: [RDF.Term.value(EX.o1())]}
      },
      RDF.Term.value(EX.graph()) => %{
        RDF.Term.value(EX.s2()) => %{p: [RDF.Term.value(EX.o2())]}
      }
    }

    assert Dataset.new([{EX.s1(), EX.p(), EX.o1()}, {EX.s2(), EX.p(), EX.o2(), EX.graph()}])
           |> Dataset.values(context: PropertyMap.new(p: EX.p())) ==
             expected_result

    assert Dataset.new([{EX.s1(), EX.p(), EX.o1()}, {EX.s2(), EX.p(), EX.o2(), EX.graph()}])
           |> Dataset.values(context: %{p: EX.p()}) ==
             expected_result
  end

  test "map/2" do
    mapping = fn
      {:graph_name, graph_name} ->
        graph_name

      {:predicate, predicate} ->
        predicate |> to_string() |> String.split("/") |> List.last() |> String.to_atom()

      {_, term} ->
        RDF.Term.value(term)
    end

    assert Dataset.new() |> Dataset.map(mapping) == %{}

    assert Dataset.new([{EX.s1(), EX.p(), EX.o1()}, {EX.s2(), EX.p(), EX.o2(), EX.graph()}])
           |> Dataset.map(mapping) ==
             %{
               nil => %{
                 RDF.Term.value(EX.s1()) => %{p: [RDF.Term.value(EX.o1())]}
               },
               EX.graph() => %{
                 RDF.Term.value(EX.s2()) => %{p: [RDF.Term.value(EX.o2())]}
               }
             }
  end

  test "equal/2" do
    triple = {EX.S, EX.p(), EX.O}
    assert Dataset.equal?(Dataset.new(triple), Dataset.new(triple))

    assert Dataset.equal?(
             Dataset.new(triple, name: EX.Dataset1),
             Dataset.new(triple, name: EX.Dataset1)
           )

    assert Dataset.equal?(
             Dataset.new(Graph.new(triple, name: EX.Graph1, prefixes: %{ex: EX})),
             Dataset.new(Graph.new(triple, name: EX.Graph1, prefixes: %{ex: RDF}))
           )

    assert Dataset.equal?(
             Dataset.new(Graph.new(triple, name: EX.Graph1, base_iri: EX.base())),
             Dataset.new(Graph.new(triple, name: EX.Graph1, base_iri: EX.other_base()))
           )

    refute Dataset.equal?(Dataset.new(triple), Dataset.new({EX.S, EX.p(), EX.O2}))

    refute Dataset.equal?(
             Dataset.new(triple, name: EX.Dataset1),
             Dataset.new(triple, name: EX.Dataset2)
           )

    refute Dataset.equal?(
             Dataset.new(Graph.new(triple, name: EX.Graph1)),
             Dataset.new(Graph.new(triple, name: EX.Graph2))
           )
  end

  test "prefixes/1" do
    assert Dataset.new()
           |> Dataset.add(Graph.new(prefixes: [ex: EX, foo: RDFS]))
           |> Dataset.add(Graph.new(name: EX.Graph, prefixes: [ex: EX, foo: OWL]))
           |> Dataset.prefixes() ==
             PrefixMap.new(ex: EX, foo: RDFS)
  end

  test "statements/1" do
    assert Dataset.new([
             {EX.S1, EX.p1(), EX.O1},
             {EX.S1, EX.p2(), EX.O2},
             {EX.S1, EX.p2(), EX.O2, EX.GraphName},
             {EX.S2, EX.p2(), EX.O2, EX.GraphName}
           ])
           |> Dataset.statements() == [
             {RDF.iri(EX.S1), EX.p1(), RDF.iri(EX.O1)},
             {RDF.iri(EX.S1), EX.p2(), RDF.iri(EX.O2)},
             {RDF.iri(EX.S1), EX.p2(), RDF.iri(EX.O2), RDF.iri(EX.GraphName)},
             {RDF.iri(EX.S2), EX.p2(), RDF.iri(EX.O2), RDF.iri(EX.GraphName)}
           ]
  end

  describe "Enumerable protocol" do
    test "Enum.count" do
      # credo:disable-for-next-line Credo.Check.Warning.ExpensiveEmptyEnumCheck
      assert Enum.count(Dataset.new(name: EX.foo())) == 0
      assert Enum.count(Dataset.new({EX.S, EX.p(), EX.O, EX.Graph})) == 1

      assert Enum.count(Dataset.new([{EX.S, EX.p(), EX.O1, EX.Graph}, {EX.S, EX.p(), EX.O2}])) ==
               2

      ds =
        Dataset.add(dataset(), [
          {EX.Subject1, EX.predicate1(), EX.Object1, EX.Graph},
          {EX.Subject1, EX.predicate2(), EX.Object2, EX.Graph},
          {EX.Subject3, EX.predicate3(), EX.Object3}
        ])

      assert Enum.count(ds) == 3
    end

    test "Enum.member?" do
      refute Enum.member?(
               Dataset.new(),
               {RDF.iri(EX.S), EX.p(), RDF.iri(EX.O), RDF.iri(EX.Graph)}
             )

      assert Enum.member?(
               Dataset.new({EX.S, EX.p(), EX.O, EX.Graph}),
               {EX.S, EX.p(), EX.O, EX.Graph}
             )

      ds =
        Dataset.add(dataset(), [
          {EX.Subject1, EX.predicate1(), EX.Object1, EX.Graph},
          {EX.Subject1, EX.predicate2(), EX.Object2, EX.Graph},
          {EX.Subject3, EX.predicate3(), EX.Object3}
        ])

      assert Enum.member?(ds, {EX.Subject1, EX.predicate1(), EX.Object1, EX.Graph})
      assert Enum.member?(ds, {EX.Subject1, EX.predicate2(), EX.Object2, EX.Graph})
      assert Enum.member?(ds, {EX.Subject3, EX.predicate3(), EX.Object3})
    end

    test "Enum.reduce" do
      ds =
        Dataset.add(dataset(), [
          {EX.Subject1, EX.predicate1(), EX.Object1, EX.Graph},
          {EX.Subject1, EX.predicate2(), EX.Object2},
          {EX.Subject3, EX.predicate3(), EX.Object3, EX.Graph}
        ])

      assert ds ==
               Enum.reduce(ds, dataset(), fn statement, acc -> acc |> Dataset.add(statement) end)
    end

    test "Enum.at (for Enumerable.slice/1)" do
      assert Dataset.new({EX.S, EX.p(), EX.O, EX.Graph})
             |> Enum.at(0) == {RDF.iri(EX.S), EX.p(), RDF.iri(EX.O), RDF.iri(EX.Graph)}
    end
  end

  describe "Collectable protocol" do
    test "with a list of triples" do
      triples = [
        {EX.Subject, EX.predicate1(), EX.Object1},
        {EX.Subject, EX.predicate2(), EX.Object2},
        {EX.Subject, EX.predicate2(), EX.Object2, EX.Graph}
      ]

      assert Enum.into(triples, Dataset.new()) == Dataset.new(triples)
    end
  end

  describe "Access behaviour" do
    test "access with the [] operator" do
      assert Dataset.new()[EX.Graph] == nil

      assert Dataset.new({EX.S, EX.p(), EX.O, EX.Graph})[EX.Graph] ==
               Graph.new({EX.S, EX.p(), EX.O}, name: EX.Graph)
    end
  end
end
