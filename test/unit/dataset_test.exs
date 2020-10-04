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
             |> named_dataset?(iri("http://example.com/DatasetName"))

      assert named_dataset(EX.Foo) |> named_dataset?(iri(EX.Foo))
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
      assert named_dataset?(ds, iri(EX.DatasetName))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate(), EX.Object})
    end

    test "creating a named dataset with an initial quad" do
      ds =
        Dataset.new({EX.Subject, EX.predicate(), EX.Object, EX.GraphName}, name: EX.DatasetName)

      assert named_dataset?(ds, iri(EX.DatasetName))

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

      assert named_dataset?(ds, iri(EX.DatasetName))
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

      assert named_dataset?(ds, iri(EX.DatasetName))
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
      assert named_dataset?(ds, iri(EX.DatasetName))
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert dataset_includes_statement?(ds, {EX.Subject, EX.predicate(), EX.Object})

      ds =
        Dataset.new(Graph.new({EX.Subject, EX.predicate(), EX.Object}, name: EX.GraphName),
          name: EX.DatasetName
        )

      assert named_dataset?(ds, iri(EX.DatasetName))
      assert unnamed_graph?(Dataset.default_graph(ds))
      assert named_graph?(Dataset.graph(ds, EX.GraphName), iri(EX.GraphName))

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
      assert named_graph?(Dataset.graph(ds, EX.GraphName), iri(EX.GraphName))

      assert dataset_includes_statement?(
               ds,
               {EX.Subject, EX.predicate(), EX.Object, EX.GraphName}
             )
    end
  end

  test "name/1" do
    assert Dataset.name(dataset()) == dataset().name
  end

  test "change_name/2" do
    assert Dataset.change_name(dataset(), EX.NewDataset).name == iri(EX.NewDataset)
    assert Dataset.change_name(named_dataset(), nil).name == nil
  end

  describe "add/3" do
    test "a proper triple is added to the default graph" do
      assert Dataset.add(dataset(), {iri(EX.Subject), EX.predicate(), iri(EX.Object)})
             |> dataset_includes_statement?({EX.Subject, EX.predicate(), EX.Object})
    end

    test "a proper quad is added to the specified graph" do
      ds =
        Dataset.add(dataset(), {iri(EX.Subject), EX.predicate(), iri(EX.Object), iri(EX.Graph)})

      assert dataset_includes_statement?(
               ds,
               {EX.Subject, EX.predicate(), EX.Object, iri(EX.Graph)}
             )
    end

    test "a proper quad with nil context is added to the default graph" do
      ds = Dataset.add(dataset(), {iri(EX.Subject), EX.predicate(), iri(EX.Object), nil})
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
      assert named_graph?(Dataset.graph(ds, EX.Graph), iri(EX.Graph))
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
      assert named_graph?(Dataset.graph(ds, EX.Graph1), iri(EX.Graph1))
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
      assert named_graph?(Dataset.graph(ds, EX.Graph2), iri(EX.Graph2))
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

      assert named_graph?(Dataset.graph(ds, EX.Graph), iri(EX.Graph))
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

      assert ds.name == iri(EX.DatasetName)
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

      assert ds.name == iri(EX.DatasetName)
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
        |> RDF.Dataset.add([
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
        |> RDF.Dataset.add([
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
        |> RDF.Dataset.add(
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

    test "duplicates are ignored" do
      ds = Dataset.add(dataset(), {EX.Subject, EX.predicate(), EX.Object, EX.GraphName})
      assert Dataset.add(ds, {EX.Subject, EX.predicate(), EX.Object, EX.GraphName}) == ds
    end

    test "non-coercible statements elements are causing an error" do
      assert_raise RDF.IRI.InvalidError, fn ->
        Dataset.add(dataset(), {"not a IRI", EX.predicate(), iri(EX.Object), iri(EX.GraphName)})
      end

      assert_raise RDF.Literal.InvalidError, fn ->
        Dataset.add(dataset(), {EX.Subject, EX.prop(), self(), nil})
      end

      assert_raise RDF.IRI.InvalidError, fn ->
        Dataset.add(dataset(), {iri(EX.Subject), EX.predicate(), iri(EX.Object), "not a IRI"})
      end

      assert_raise RDF.IRI.InvalidError, fn ->
        Dataset.add(dataset(), {iri(EX.Subject), EX.predicate(), iri(EX.Object)},
          graph: "not a IRI"
        )
      end
    end
  end

  describe "put/3" do
    test "a list of statements without an overwriting graph context" do
      ds =
        Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2, EX.Graph}])
        |> RDF.Dataset.put([
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
        |> RDF.Dataset.put(
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
        |> RDF.Dataset.put(
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
        |> Dataset.put([
          {EX.S1, [{EX.p1(), EX.O2}]},
          {EX.S2, %{EX.p1() => EX.O2}},
          {EX.S3, %{EX.p3() => EX.O3}}
        ])

      assert dataset_includes_statement?(ds, {EX.S1, EX.p1(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p2(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p1(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S3, EX.p3(), EX.O3})
    end

    test "maps" do
      ds =
        Dataset.new([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}])
        |> Dataset.put(%{
          EX.S1 => [{EX.p1(), EX.O2}],
          EX.S2 => %{EX.p1() => EX.O2},
          EX.S3 => %{EX.p3() => EX.O3}
        })

      assert dataset_includes_statement?(ds, {EX.S1, EX.p1(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p2(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S2, EX.p1(), EX.O2})
      assert dataset_includes_statement?(ds, {EX.S3, EX.p3(), EX.O3})
    end

    test "descriptions" do
      ds =
        Dataset.new([{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}, {EX.S1, EX.P3, EX.O3}])
        |> RDF.Dataset.put(
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
        |> RDF.Dataset.put(Graph.new([{EX.S1, EX.P3, EX.O4}, {EX.S1, EX.P2, bnode(:foo)}]))

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
        |> RDF.Dataset.put(
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
        |> RDF.Dataset.put([
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

    test "simultaneous use of the different forms to address the default context" do
      ds =
        RDF.Dataset.put(dataset(), [
          {EX.S, EX.P, EX.O1},
          {EX.S, EX.P, EX.O2, nil}
        ])

      assert Dataset.statement_count(ds) == 2
      assert dataset_includes_statement?(ds, {EX.S, EX.P, EX.O1})
      assert dataset_includes_statement?(ds, {EX.S, EX.P, EX.O2})
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
    assert quad == {iri(EX.S), iri(EX.p()), iri(EX.O), iri(EX.Graph)}
    assert Enum.count(dataset.graphs) == 0

    {{subject, predicate, object, _}, dataset} =
      Dataset.new([{EX.S, EX.p(), EX.O, EX.Graph}, {EX.S, EX.p(), EX.O}])
      |> Dataset.pop()

    assert {subject, predicate, object} == {iri(EX.S), iri(EX.p()), iri(EX.O)}
    assert Enum.count(dataset.graphs) == 1

    {{subject, _, _, graph_context}, dataset} =
      Dataset.new([{EX.S, EX.p(), EX.O1, EX.Graph}, {EX.S, EX.p(), EX.O2, EX.Graph}])
      |> Dataset.pop()

    assert subject == iri(EX.S)
    assert graph_context == iri(EX.Graph)
    assert Enum.count(dataset.graphs) == 1
  end

  test "include?/3" do
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
    mapping = fn
      {:graph_name, graph_name} ->
        graph_name

      {:predicate, predicate} ->
        predicate |> to_string() |> String.split("/") |> List.last() |> String.to_atom()

      {_, term} ->
        RDF.Term.value(term)
    end

    assert Dataset.new() |> Dataset.values(mapping) == %{}

    assert Dataset.new([{EX.s1(), EX.p(), EX.o1()}, {EX.s2(), EX.p(), EX.o2(), EX.graph()}])
           |> Dataset.values(mapping) ==
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

  describe "Enumerable protocol" do
    test "Enum.count" do
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
      refute Enum.member?(Dataset.new(), {iri(EX.S), EX.p(), iri(EX.O), iri(EX.Graph)})

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

    test "with a list of lists" do
      lists = [
        [EX.Subject, EX.predicate1(), EX.Object1],
        [EX.Subject, EX.predicate2(), EX.Object2],
        [EX.Subject, EX.predicate2(), EX.Object2, EX.Graph]
      ]

      assert Enum.into(lists, Dataset.new()) ==
               Dataset.new(Enum.map(lists, &List.to_tuple/1))
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
