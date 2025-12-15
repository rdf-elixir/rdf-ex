defmodule RDF.Data.SourceTest do
  use RDF.Test.Case

  doctest RDF.Data.Source

  alias RDF.Data.Source

  test "structure_type/1" do
    assert Source.structure_type(description()) == :description
    assert Source.structure_type(graph()) == :graph
    assert Source.structure_type(unnamed_graph()) == :graph
    assert Source.structure_type(named_graph()) == :graph
    assert Source.structure_type(dataset()) == :dataset
    assert Source.structure_type(unnamed_dataset()) == :dataset
    assert Source.structure_type(named_dataset()) == :dataset
  end

  describe "reduce/3" do
    test "reduces over RDF.Description triples" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert {:done, result} =
               Source.reduce(desc, {:cont, []}, fn {_, _, _} = triple, acc ->
                 {:cont, [triple | acc]}
               end)

      assert Enum.sort(result) == [
               {RDF.iri(EX.S), EX.p1(), RDF.iri(EX.O1)},
               {RDF.iri(EX.S), EX.p2(), RDF.iri(EX.O2)}
             ]
    end

    test "reduces over RDF.Graph triples" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p2(), EX.O2}
        ])

      assert {:done, result} =
               Source.reduce(graph, {:cont, []}, fn {_, _, _} = triple, acc ->
                 {:cont, [triple | acc]}
               end)

      assert Enum.sort(result) == [
               {RDF.iri(EX.S1), EX.p1(), RDF.iri(EX.O1)},
               {RDF.iri(EX.S2), EX.p2(), RDF.iri(EX.O2)}
             ]
    end

    test "reduces over RDF.Dataset statements (quads)" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.Graph}
        ])

      assert {:done, result} =
               Source.reduce(dataset, {:cont, []}, fn statement, acc ->
                 {:cont, [statement | acc]}
               end)

      assert Enum.sort(result) == [
               {RDF.iri(EX.S1), EX.p1(), RDF.iri(EX.O1), nil},
               {RDF.iri(EX.S2), EX.p2(), RDF.iri(EX.O2), RDF.iri(EX.Graph)}
             ]
    end
  end

  describe "statement_count/1" do
    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)
      assert Source.statement_count(desc) == {:ok, 2}
    end

    test "RDF.Graph" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p1(), EX.O3}
        ])

      assert Source.statement_count(graph) == {:ok, 3}
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.Graph}
        ])

      assert Source.statement_count(dataset) == {:ok, 2}
    end
  end

  describe "description_count/1" do
    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)
      assert Source.description_count(desc) == {:ok, 1}

      empty_desc = RDF.description(EX.S)
      assert Source.description_count(empty_desc) == {:ok, 0}
    end

    test "RDF.Graph" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p1(), EX.O3}
        ])

      assert Source.description_count(graph) == {:ok, 2}
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.Graph},
          {EX.S1, EX.p3(), EX.O3, EX.Graph}
        ])

      assert Source.description_count(dataset) == {:ok, 2}
    end
  end

  describe "graph_count/1" do
    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)
      assert Source.graph_count(desc) == {:ok, 1}

      empty_desc = RDF.description(EX.S)
      assert Source.graph_count(empty_desc) == {:ok, 1}
    end

    test "RDF.Graph" do
      graph =
        RDF.graph([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S2, EX.p2(), EX.O2}
        ])

      assert Source.graph_count(graph) == {:ok, 1}

      empty_graph = RDF.graph()
      assert Source.graph_count(empty_graph) == {:ok, 1}
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.Graph1},
          {EX.S3, EX.p3(), EX.O3, EX.Graph2}
        ])

      assert Source.graph_count(dataset) == {:ok, 3}

      empty_dataset = RDF.dataset()
      assert Source.graph_count(empty_dataset) == {:ok, 0}
    end
  end

  describe "graph/2" do
    test "RDF.Description returns itself as unnamed graph when graph_name is nil" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert Source.graph(desc, nil) == {:ok, RDF.Graph.new(desc)}
    end

    test "RDF.Description returns :error when graph_name is not nil" do
      desc = EX.S |> EX.p1(EX.O1)

      assert Source.graph(desc, RDF.iri(EX.Graph1)) == :error
      assert Source.graph(desc, EX.Graph1) == :error
    end

    test "RDF.Graph returns itself when name matches" do
      unnamed_graph = RDF.graph([{EX.S, EX.p(), EX.O}])
      assert Source.graph(unnamed_graph, nil) == {:ok, unnamed_graph}

      named_graph = RDF.graph([{EX.S, EX.p(), EX.O}], name: EX.Graph1)
      assert Source.graph(named_graph, RDF.iri(EX.Graph1)) == {:ok, named_graph}
      assert Source.graph(named_graph, EX.Graph1) == {:ok, named_graph}
    end

    test "RDF.Graph returns :error when name doesn't match" do
      graph = RDF.graph([{EX.S, EX.p(), EX.O}], name: EX.Graph1)

      assert Source.graph(graph, EX.Graph2) == :error
      assert Source.graph(graph, nil) == :error
    end

    test "RDF.Dataset returns existing graph when found" do
      default_graph = RDF.graph({EX.S1, EX.p1(), EX.O1})
      named_graph1 = RDF.graph({EX.S2, EX.p2(), EX.O2}, name: EX.Graph1)
      named_graph2 = RDF.graph({EX.S3, EX.p3(), EX.O3}, name: EX.Graph2)
      dataset = RDF.dataset([default_graph, named_graph1, named_graph2])

      assert Source.graph(dataset, nil) == {:ok, default_graph}
      assert Source.graph(dataset, RDF.iri(EX.Graph1)) == {:ok, named_graph1}
      assert Source.graph(dataset, EX.Graph2) == {:ok, named_graph2}
    end

    test "RDF.Dataset returns :error when not found" do
      dataset = RDF.dataset([{EX.S1, EX.p1(), EX.O1, EX.Graph1}])

      assert Source.graph(dataset, EX.Graph2) == :error
      assert Source.graph(dataset, nil) == :error
    end
  end

  describe "description/2" do
    test "RDF.Description returns the given data unchanged when subject matches" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert Source.description(desc, EX.S) == {:ok, desc}
      assert Source.description(desc, RDF.iri(EX.S)) == {:ok, desc}
    end

    test "RDF.Description returns :error when subject doesn't match" do
      desc = EX.S1 |> EX.p1(EX.O1)

      assert Source.description(desc, EX.S2) == :error
    end

    test "RDF.Graph returns description using existing Graph.description/2" do
      desc1 = EX.S1 |> EX.p1(EX.O1) |> EX.p2(EX.O2)
      desc2 = EX.S2 |> EX.p3(EX.O3)
      graph = RDF.graph([desc1, desc2])

      assert Source.description(graph, EX.S1) == {:ok, desc1}
      assert Source.description(graph, RDF.iri(EX.S2)) == {:ok, desc2}

      assert Source.description(graph, EX.NonExistent) == :error
    end

    test "RDF.Dataset aggregates descriptions across all graphs" do
      dataset =
        RDF.dataset([
          # S1 appears in both default and named graph
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S1, EX.p2(), EX.O2, EX.Graph1},
          # S2 only in named graph
          {EX.S2, EX.p3(), EX.O3, EX.Graph1},
          # S3 in different named graph
          {EX.S3, EX.p4(), EX.O4, EX.Graph2}
        ])

      assert Source.description(dataset, EX.S1) ==
               {:ok, EX.S1 |> EX.p1(EX.O1) |> EX.p2(EX.O2)}

      assert Source.description(dataset, EX.S2) == {:ok, EX.S2 |> EX.p3(EX.O3)}
      assert Source.description(dataset, EX.S3) == {:ok, EX.S3 |> EX.p4(EX.O4)}

      assert Source.description(dataset, EX.NotThere) == :error
    end
  end

  describe "subjects/1" do
    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)
      assert Source.subjects(desc) == {:ok, [RDF.iri(EX.S)]}

      empty_desc = RDF.Description.new(EX.S)
      assert Source.subjects(empty_desc) == {:ok, []}
    end

    test "RDF.Graph" do
      graph =
        RDF.Graph.new([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p3(), EX.O3}
        ])

      assert {:ok, subjects} = Source.subjects(graph)
      assert Enum.sort(subjects) == [RDF.iri(EX.S1), RDF.iri(EX.S2)]

      assert Source.subjects(RDF.Graph.new()) == {:ok, []}
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S1, EX.p2(), EX.O2, EX.Graph1},
          {EX.S2, EX.p3(), EX.O3, EX.Graph1},
          {EX.S3, EX.p4(), EX.O4, EX.Graph2}
        ])

      assert {:ok, subjects} = Source.subjects(dataset)
      assert Enum.sort(subjects) == [RDF.iri(EX.S1), RDF.iri(EX.S2), RDF.iri(EX.S3)]

      assert Source.subjects(RDF.Dataset.new()) == {:ok, []}
    end
  end

  describe "predicates/1" do
    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert {:ok, predicates} = Source.predicates(desc)
      assert Enum.sort(predicates) == [EX.p1(), EX.p2()]

      empty_desc = RDF.Description.new(EX.S)
      assert Source.predicates(empty_desc) == {:ok, []}
    end

    test "RDF.Graph" do
      graph =
        RDF.Graph.new([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p1(), EX.O3},
          {EX.S2, EX.p3(), EX.O4}
        ])

      assert {:ok, predicates} = Source.predicates(graph)
      expected = RDF.Graph.predicates(graph) |> MapSet.to_list()
      assert Enum.sort(predicates) == Enum.sort(expected)

      assert Source.predicates(RDF.Graph.new()) == {:ok, []}
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S1, EX.p2(), EX.O2, EX.Graph1},
          {EX.S2, EX.p3(), EX.O3, EX.Graph1},
          # p1 appears in multiple graphs
          {EX.S3, EX.p1(), EX.O4, EX.Graph2}
        ])

      assert {:ok, predicates} = Source.predicates(dataset)
      expected = RDF.Dataset.predicates(dataset) |> MapSet.to_list()
      assert Enum.sort(predicates) == Enum.sort(expected)

      assert Source.predicates(RDF.Dataset.new()) == {:ok, []}
    end
  end

  describe "objects/1" do
    test "RDF.Graph uses existing Graph.objects implementation" do
      graph =
        RDF.Graph.new([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), EX.O2},
          {EX.S2, EX.p1(), EX.O1},
          {EX.S2, EX.p3(), "literal"}
        ])

      assert {:ok, objects} = Source.objects(graph)
      expected = RDF.Graph.objects(graph) |> MapSet.to_list()
      assert Enum.sort(objects) == Enum.sort(expected)
    end

    test "RDF.Description returns {:error, __MODULE__} - not optimized" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)

      assert {:error, _module} = Source.objects(desc)
    end

    test "RDF.Dataset returns {:error, __MODULE__} - not optimized" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.Graph1}
        ])

      assert {:error, _module} = Source.objects(dataset)
    end
  end

  describe "resources/1" do
    test "RDF.Graph combines subjects and non-literal objects" do
      graph =
        RDF.Graph.new([
          {EX.S1, EX.p1(), EX.O1},
          {EX.S1, EX.p2(), "literal"},
          {EX.S2, EX.p3(), ~B<blank>},
          {~B<b1>, EX.p4(), EX.O2}
        ])

      assert {:ok, resources} = Source.resources(graph)

      assert MapSet.new(resources) ==
               MapSet.new([
                 RDF.iri(EX.S1),
                 RDF.iri(EX.S2),
                 RDF.iri(EX.O1),
                 RDF.iri(EX.O2),
                 RDF.bnode("blank"),
                 RDF.bnode("b1")
               ])
    end

    test "RDF.Description returns {:error, __MODULE__} - not optimized" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2("literal")

      assert {:error, _module} = Source.resources(desc)
    end

    test "Dataset returns {:error, __MODULE__} - not optimized" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), "literal", EX.Graph1}
        ])

      assert {:error, _module} = Source.resources(dataset)
    end
  end

  describe "graph_names/1" do
    test "RDF.Description" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)
      assert Source.graph_names(desc) == {:ok, [nil]}

      desc = RDF.Description.new(EX.S)
      assert Source.graph_names(desc) == {:ok, [nil]}
    end

    test "RDF.Graph" do
      unnamed_graph = RDF.graph([{EX.S, EX.p(), EX.O}])
      assert Source.graph_names(unnamed_graph) == {:ok, [nil]}

      named_graph = RDF.graph([{EX.S, EX.p(), EX.O}], name: EX.Graph1)
      assert Source.graph_names(named_graph) == {:ok, [RDF.iri(EX.Graph1)]}

      empty_named_graph = RDF.graph([], name: EX.Graph2)
      assert Source.graph_names(empty_named_graph) == {:ok, [RDF.iri(EX.Graph2)]}
    end

    test "RDF.Dataset" do
      dataset =
        RDF.dataset([
          {EX.S1, EX.p1(), EX.O1, nil},
          {EX.S2, EX.p2(), EX.O2, EX.Graph1},
          {EX.S3, EX.p3(), EX.O3, EX.Graph2}
        ])

      assert {:ok, graph_names} = Source.graph_names(dataset)
      assert Enum.sort(graph_names) == Enum.sort([nil, RDF.iri(EX.Graph1), RDF.iri(EX.Graph2)])

      empty_dataset = RDF.dataset()
      assert Source.graph_names(empty_dataset) == {:ok, []}

      dataset_default_only = RDF.dataset([{EX.S, EX.p(), EX.O, nil}])
      assert Source.graph_names(dataset_default_only) == {:ok, [nil]}

      dataset_named_only =
        RDF.dataset([
          {EX.S1, EX.p(), EX.O1, EX.Graph1},
          {EX.S2, EX.p(), EX.O2, EX.Graph2}
        ])

      assert {:ok, graph_names} = Source.graph_names(dataset_named_only)
      assert Enum.sort(graph_names) == Enum.sort([RDF.iri(EX.Graph1), RDF.iri(EX.Graph2)])
    end
  end

  describe "add/2" do
    test "RDF.Description adds triples" do
      desc = EX.S |> EX.p1(EX.O1)

      assert Source.add(desc, {EX.S, EX.p2(), EX.O2}) ==
               {:ok, EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)}
    end

    test "RDF.Description adds list of triples" do
      desc = EX.S |> EX.p1(EX.O1)

      assert Source.add(desc, [{EX.S, EX.p2(), EX.O2}, {EX.S, EX.p3(), EX.O3}]) ==
               {:ok, EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2) |> EX.p3(EX.O3)}
    end

    test "RDF.Graph adds triples" do
      graph = RDF.graph({EX.S1, EX.p1(), EX.O1})

      assert Source.add(graph, {EX.S2, EX.p2(), EX.O2}) ==
               {:ok, RDF.graph([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}])}
    end

    test "RDF.Graph adds quads by stripping graph component" do
      graph = RDF.graph({EX.S1, EX.p1(), EX.O1})

      assert Source.add(graph, {EX.S2, EX.p2(), EX.O2, EX.G}) ==
               {:ok, RDF.graph([{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}])}
    end

    test "RDF.Dataset adds quads" do
      dataset = RDF.dataset({EX.S1, EX.p1(), EX.O1, EX.G1})

      assert Source.add(dataset, {EX.S2, EX.p2(), EX.O2, EX.G2}) ==
               {:ok,
                RDF.dataset([{EX.S1, EX.p1(), EX.O1, EX.G1}, {EX.S2, EX.p2(), EX.O2, EX.G2}])}
    end

    test "RDF.Dataset adds triples to default graph" do
      dataset = RDF.dataset({EX.S1, EX.p1(), EX.O1, EX.G1})

      assert Source.add(dataset, {EX.S2, EX.p2(), EX.O2}) ==
               {:ok, RDF.dataset([{EX.S1, EX.p1(), EX.O1, EX.G1}, {EX.S2, EX.p2(), EX.O2, nil}])}
    end
  end

  describe "subject/1" do
    test "RDF.Description returns subject" do
      desc = EX.S |> EX.p1(EX.O1) |> EX.p2(EX.O2)
      assert Source.subject(desc) == RDF.iri(EX.S)

      empty_desc = RDF.description(EX.S)
      assert Source.subject(empty_desc) == RDF.iri(EX.S)
    end

    test "RDF.Graph returns nil" do
      graph = RDF.graph([{EX.S, EX.p(), EX.O}])
      assert Source.subject(graph) == nil

      empty_graph = RDF.graph()
      assert Source.subject(empty_graph) == nil
    end

    test "RDF.Dataset returns nil" do
      dataset = RDF.dataset([{EX.S, EX.p(), EX.O, nil}])
      assert Source.subject(dataset) == nil

      empty_dataset = RDF.dataset()
      assert Source.subject(empty_dataset) == nil
    end
  end

  describe "graph_name/1" do
    test "RDF.Description returns nil" do
      desc = EX.S |> EX.p1(EX.O1)
      assert Source.graph_name(desc) == nil

      empty_desc = RDF.description(EX.S)
      assert Source.graph_name(empty_desc) == nil
    end

    test "RDF.Graph returns graph name" do
      unnamed_graph = RDF.graph([{EX.S, EX.p(), EX.O}])
      assert Source.graph_name(unnamed_graph) == nil

      named_graph = RDF.graph([{EX.S, EX.p(), EX.O}], name: EX.Graph1)
      assert Source.graph_name(named_graph) == RDF.iri(EX.Graph1)

      empty_named_graph = RDF.graph([], name: EX.Graph2)
      assert Source.graph_name(empty_named_graph) == RDF.iri(EX.Graph2)
    end

    test "RDF.Dataset returns nil" do
      unnamed_dataset = RDF.dataset([{EX.S, EX.p(), EX.O, nil}])
      assert Source.graph_name(unnamed_dataset) == nil

      named_dataset = RDF.dataset([{EX.S, EX.p(), EX.O, nil}], name: EX.Dataset1)
      assert Source.graph_name(named_dataset) == nil

      empty_named_dataset = RDF.dataset(name: EX.Dataset2)
      assert Source.graph_name(empty_named_dataset) == nil
    end
  end

  describe "derive/3 from RDF.Description" do
    test "to :description uses template subject by default" do
      template = RDF.description(EX.Template)

      assert Source.derive(template, :description) ==
               {:ok, RDF.description(EX.Template)}
    end

    test "to :description with :subject option overrides template subject" do
      template = RDF.description(EX.Template)

      assert Source.derive(template, :description, subject: EX.Other) ==
               {:ok, RDF.description(EX.Other)}
    end

    test "to :graph creates empty graph" do
      template = RDF.description(EX.Template)

      assert Source.derive(template, :graph) ==
               {:ok, RDF.graph()}
    end

    test "to :dataset creates empty dataset" do
      template = RDF.description(EX.Template)

      assert Source.derive(template, :dataset) ==
               {:ok, RDF.dataset()}
    end
  end

  describe "derive/3 from RDF.Graph" do
    test "to :description with :subject option" do
      template = RDF.graph(name: EX.Template)

      assert Source.derive(template, :description, subject: EX.S) ==
               {:ok, RDF.description(EX.S)}
    end

    test "to :description without :subject option returns error" do
      template = RDF.graph(name: EX.Template)

      assert Source.derive(template, :description) ==
               {:error, :no_subject}
    end

    test "to :graph with preserve_metadata: true (default) preserves name, prefixes, base_iri" do
      template =
        RDF.graph(name: EX.Template, prefixes: [ex: EX], base_iri: "http://example.com/")

      assert Source.derive(template, :graph) ==
               {:ok,
                RDF.graph(
                  name: EX.Template,
                  prefixes: [ex: EX],
                  base_iri: "http://example.com/"
                )}
    end

    test "to :graph with preserve_metadata: false creates plain graph" do
      template =
        RDF.graph(name: EX.Template, prefixes: [ex: EX], base_iri: "http://example.com/")

      assert Source.derive(template, :graph, preserve_metadata: false) ==
               {:ok, RDF.graph()}
    end

    test "to :dataset creates empty dataset" do
      template = RDF.graph(name: EX.Template)

      assert Source.derive(template, :dataset) ==
               {:ok, RDF.dataset()}
    end
  end

  describe "derive/3 from RDF.Dataset" do
    test "to :description with :subject option" do
      template = RDF.dataset(name: EX.Template)

      assert Source.derive(template, :description, subject: EX.S) ==
               {:ok, RDF.description(EX.S)}
    end

    test "to :description without :subject option returns error" do
      template = RDF.dataset(name: EX.Template)

      assert Source.derive(template, :description) ==
               {:error, :no_subject}
    end

    test "to :graph creates empty graph" do
      template = RDF.dataset(name: EX.Template)

      assert Source.derive(template, :graph) ==
               {:ok, RDF.graph()}
    end

    test "to :dataset with preserve_metadata: true (default) preserves name" do
      template = RDF.dataset(name: EX.Template)

      assert Source.derive(template, :dataset) ==
               {:ok, RDF.dataset(name: EX.Template)}
    end

    test "to :dataset with preserve_metadata: false creates plain dataset" do
      template = RDF.dataset(name: EX.Template)

      assert Source.derive(template, :dataset, preserve_metadata: false) ==
               {:ok, RDF.dataset()}
    end
  end
end
