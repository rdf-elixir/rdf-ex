defmodule RDF.DataTest do
  use RDF.Test.Case

  setup do
    description =
      EX.S
      |> EX.p1(EX.O1, EX.O2)
      |> EX.p2(EX.O3)
      |> EX.p3(~B<foo>, ~L"bar")
    graph =
      Graph.new
      |> Graph.add(description)
      |> Graph.add(
          EX.S2
          |> EX.p2(EX.O3, EX.O4)
      )
    named_graph = %Graph{graph | name: uri(EX.NamedGraph)}
    dataset =
      Dataset.new
      |> Dataset.add(graph)
      |> Dataset.add(
          Graph.new(EX.NamedGraph)
          |> Graph.add(description)
          |> Graph.add({EX.S3, EX.p3, EX.O5})
          |> Graph.add({EX.S, EX.p3, EX.O5}))
    {:ok,
      description: description,
      graph: graph, named_graph: named_graph,
      dataset: dataset,
    }
  end


  describe "RDF.Data protocol implementation of RDF.Description" do
    test "merge of a single triple with different subject", %{description: description} do
      assert RDF.Data.merge(description, {EX.Other, EX.p1, EX.O3}) ==
              Graph.new(description) |> Graph.add({EX.Other, EX.p1, EX.O3})
    end

    test "merge of a single triple with same subject", %{description: description} do
      assert RDF.Data.merge(description, {EX.S, EX.p1, EX.O3}) ==
              Description.add(description, {EX.S, EX.p1, EX.O3})
    end

    test "merge of a single quad", %{description: description} do
      assert RDF.Data.merge(description, {EX.Other, EX.p1, EX.O3, EX.Graph}) ==
              Dataset.new(description) |> Dataset.add({EX.Other, EX.p1, EX.O3, EX.Graph})
      assert RDF.Data.merge(description, {EX.S, EX.p1, EX.O3, EX.Graph}) ==
              Dataset.new(description) |> Dataset.add({EX.S, EX.p1, EX.O3, EX.Graph})
    end

    test "merge of a description with different subject", %{description: description} do
      assert RDF.Data.merge(description, Description.new({EX.Other, EX.p1, EX.O3})) ==
              Graph.new(description) |> Graph.add({EX.Other, EX.p1, EX.O3})
    end

    test "merge of a description with same subject", %{description: description} do
      assert RDF.Data.merge(description, Description.new({EX.S, EX.p1, EX.O3})) ==
              Description.add(description, {EX.S, EX.p1, EX.O3})
    end

    test "merge of a graph", %{graph: graph} do
      assert RDF.Data.merge(Description.new({EX.Other, EX.p1, EX.O3}), graph) ==
              Graph.add(graph, {EX.Other, EX.p1, EX.O3})
    end

    test "merge of a dataset", %{dataset: dataset} do
      assert RDF.Data.merge(Description.new({EX.Other, EX.p1, EX.O3}), dataset) ==
              Dataset.add(dataset, {EX.Other, EX.p1, EX.O3})
    end


    test "delete", %{description: description} do
      assert RDF.Data.delete(description, {EX.S, EX.p1, EX.O2}) ==
          Description.delete(description, {EX.S, EX.p1, EX.O2})
      assert RDF.Data.delete(description, {EX.Other, EX.p1, EX.O2}) == description
    end

    test "deleting a Description with a different subject does nothing", %{description: description} do
      assert RDF.Data.delete(description,
              %Description{description | subject: EX.Other}) == description
    end


    test "pop", %{description: description} do
      assert RDF.Data.pop(description) == Description.pop(description)
    end

    test "include?", %{description: description} do
      assert RDF.Data.include?(description, {EX.S, EX.p1, EX.O2})
      refute RDF.Data.include?(description, {EX.Other, EX.p1, EX.O2})
    end

    test "statements", %{description: description} do
      assert RDF.Data.statements(description) == Description.statements(description)
    end

    test "description when the requested subject matches the Description.subject",
          %{description: description} do
      assert RDF.Data.description(description, description.subject) == description
      assert RDF.Data.description(description, to_string(description.subject)) == description
      assert RDF.Data.description(description, EX.S) == description
    end

    test "description when the requested subject does not match the Description.subject",
          %{description: description} do
      assert RDF.Data.description(description, uri(EX.Other)) == Description.new(EX.Other)
    end

    test "descriptions", %{description: description} do
      assert RDF.Data.descriptions(description) == [description]
    end

    test "subjects", %{description: description} do
      assert RDF.Data.subjects(description) == MapSet.new([uri(EX.S)])
    end

    test "predicates", %{description: description} do
      assert RDF.Data.predicates(description) == MapSet.new([EX.p1, EX.p2, EX.p3])
    end

    test "objects", %{description: description} do
      assert RDF.Data.objects(description) ==
              MapSet.new([uri(EX.O1), uri(EX.O2), uri(EX.O3), ~B<foo>])
    end

    test "resources", %{description: description} do
      assert RDF.Data.resources(description) ==
              MapSet.new([uri(EX.S), EX.p1, EX.p2, EX.p3, uri(EX.O1), uri(EX.O2), uri(EX.O3), ~B<foo>])
    end

    test "subject_count", %{description: description} do
      assert RDF.Data.subject_count(description) == 1
    end

    test "statement_count", %{description: description} do
      assert RDF.Data.statement_count(description) == 5
    end
  end


  describe "RDF.Data protocol implementation of RDF.Graph" do
    test "merge of a single triple", %{graph: graph, named_graph: named_graph} do
      assert RDF.Data.merge(graph, {EX.Other, EX.p, EX.O}) ==
              Graph.add(graph, {EX.Other, EX.p, EX.O})
      assert RDF.Data.merge(named_graph, {EX.Other, EX.p, EX.O}) ==
              Graph.add(named_graph, {EX.Other, EX.p, EX.O})
    end

    test "merge of a single quad with the same graph context",
          %{graph: graph, named_graph: named_graph} do
      assert RDF.Data.merge(graph, {EX.Other, EX.p, EX.O, nil}) ==
              Graph.add(graph, {EX.Other, EX.p, EX.O})
      assert RDF.Data.merge(named_graph, {EX.Other, EX.p, EX.O, EX.NamedGraph}) ==
              Graph.add(named_graph, {EX.Other, EX.p, EX.O})
    end

    test "merge of a single quad with a different graph context",
          %{graph: graph, named_graph: named_graph} do
      assert RDF.Data.merge(graph, {EX.S, EX.p1, EX.O3, EX.NamedGraph}) ==
              Dataset.new(graph) |> Dataset.add({EX.S, EX.p1, EX.O3, EX.NamedGraph})
      assert RDF.Data.merge(named_graph, {EX.S, EX.p1, EX.O3, nil}) ==
              Dataset.new(named_graph) |> Dataset.add({EX.S, EX.p1, EX.O3, nil})
    end

    test "merge of a description", %{graph: graph} do
      assert RDF.Data.merge(graph, Description.new({EX.Other, EX.p1, EX.O3})) ==
              Graph.add(graph, {EX.Other, EX.p1, EX.O3})
      assert RDF.Data.merge(graph, Description.new({EX.S, EX.p1, EX.O3})) ==
              Graph.add(graph, {EX.S, EX.p1, EX.O3})
    end

    test "merge of a graph with the same name",
          %{graph: graph, named_graph: named_graph} do
      assert RDF.Data.merge(graph, Graph.add(graph, {EX.Other, EX.p1, EX.O3})) ==
              Graph.add(graph, {EX.Other, EX.p1, EX.O3})
      assert RDF.Data.merge(named_graph, Graph.add(named_graph, {EX.Other, EX.p1, EX.O3})) ==
              Graph.add(named_graph, {EX.Other, EX.p1, EX.O3})
    end

    test "merge of a graph with a different name",
          %{graph: graph, named_graph: named_graph} do
      assert RDF.Data.merge(graph, named_graph) ==
              Dataset.new(graph) |> Dataset.add(named_graph)
      assert RDF.Data.merge(named_graph, graph) ==
              Dataset.new(named_graph) |> Dataset.add(graph)
    end

    test "merge of a dataset", %{dataset: dataset} do
      assert RDF.Data.merge(Graph.new({EX.Other, EX.p1, EX.O3}), dataset) ==
              Dataset.add(dataset, {EX.Other, EX.p1, EX.O3})
      assert RDF.Data.merge(Graph.new(EX.NamedGraph, {EX.Other, EX.p1, EX.O3}), dataset) ==
              Dataset.add(dataset, {EX.Other, EX.p1, EX.O3, EX.NamedGraph})
    end


    test "delete", %{graph: graph} do
      assert RDF.Data.delete(graph, {EX.S, EX.p1, EX.O2}) ==
                Graph.delete(graph, {EX.S, EX.p1, EX.O2})
      assert RDF.Data.delete(graph, {EX.Other, EX.p1, EX.O2}) == graph
    end

    test "deleting a Graph with a different name does nothing", %{graph: graph} do
      assert RDF.Data.delete(graph,
              %Graph{graph | name: EX.OtherGraph}) == graph
    end

    test "pop", %{graph: graph} do
      assert RDF.Data.pop(graph) == Graph.pop(graph)
    end

    test "include?", %{graph: graph} do
      assert RDF.Data.include?(graph, {EX.S, EX.p1, EX.O2})
      assert RDF.Data.include?(graph, {EX.S2, EX.p2, EX.O3})
      refute RDF.Data.include?(graph, {EX.Other, EX.p1, EX.O2})
    end

    test "statements", %{graph: graph} do
      assert RDF.Data.statements(graph) == Graph.statements(graph)
    end

    test "description when a description is present",
          %{graph: graph, description: description} do
      assert RDF.Data.description(graph, uri(EX.S)) == description
      assert RDF.Data.description(graph, EX.S) == description
    end

    test "description when a description is not present", %{graph: graph} do
      assert RDF.Data.description(graph, uri(EX.Other)) == Description.new(EX.Other)
    end

    test "descriptions", %{graph: graph, description: description} do
      assert RDF.Data.descriptions(graph) ==
              [description, EX.S2 |> EX.p2(EX.O3, EX.O4)]
    end

    test "subjects", %{graph: graph} do
      assert RDF.Data.subjects(graph) == MapSet.new([uri(EX.S), uri(EX.S2)])
    end

    test "predicates", %{graph: graph} do
      assert RDF.Data.predicates(graph) == MapSet.new([EX.p1, EX.p2, EX.p3])
    end

    test "objects", %{graph: graph} do
      assert RDF.Data.objects(graph) ==
              MapSet.new([uri(EX.O1), uri(EX.O2), uri(EX.O3), uri(EX.O4), ~B<foo>])
    end

    test "resources", %{graph: graph} do
      assert RDF.Data.resources(graph) == MapSet.new([
              uri(EX.S), uri(EX.S2), EX.p1, EX.p2, EX.p3,
              uri(EX.O1), uri(EX.O2), uri(EX.O3), uri(EX.O4), ~B<foo>
             ])
    end

    test "subject_count", %{graph: graph} do
      assert RDF.Data.subject_count(graph) == 2
    end

    test "statement_count", %{graph: graph} do
      assert RDF.Data.statement_count(graph) == 7
    end
  end


  describe "RDF.Data protocol implementation of RDF.Dataset" do
    test "merge of a single triple", %{dataset: dataset} do
      assert RDF.Data.merge(dataset, {EX.Other, EX.p, EX.O}) ==
              Dataset.add(dataset, {EX.Other, EX.p, EX.O})
    end

    test "merge of a single quad", %{dataset: dataset} do
      assert RDF.Data.merge(dataset, {EX.Other, EX.p, EX.O, nil}) ==
          Dataset.add(dataset, {EX.Other, EX.p, EX.O})
      assert RDF.Data.merge(dataset, {EX.Other, EX.p, EX.O, EX.NamedGraph}) ==
          Dataset.add(dataset, {EX.Other, EX.p, EX.O, EX.NamedGraph})
    end

    test "merge of a description", %{dataset: dataset} do
      assert RDF.Data.merge(dataset, Description.new({EX.Other, EX.p1, EX.O3})) ==
              Dataset.add(dataset, {EX.Other, EX.p1, EX.O3})
    end

    test "merge of a graph", %{dataset: dataset} do
      assert RDF.Data.merge(dataset, Graph.new({EX.Other, EX.p1, EX.O3})) ==
              Dataset.add(dataset, {EX.Other, EX.p1, EX.O3})
      assert RDF.Data.merge(dataset, Graph.new(EX.NamedGraph, {EX.Other, EX.p1, EX.O3})) ==
              Dataset.add(dataset, {EX.Other, EX.p1, EX.O3, EX.NamedGraph})
    end

    test "merge of a dataset", %{dataset: dataset} do
      assert RDF.Data.merge(dataset, Dataset.new({EX.Other, EX.p1, EX.O3})) ==
              Dataset.add(dataset, {EX.Other, EX.p1, EX.O3})
      assert RDF.Data.merge(dataset, Dataset.new(EX.NamedDataset, {EX.Other, EX.p1, EX.O3})) ==
              Dataset.add(dataset, {EX.Other, EX.p1, EX.O3})
    end


    test "delete", %{dataset: dataset} do
      assert RDF.Data.delete(dataset, {EX.S, EX.p1, EX.O2}) ==
                Dataset.delete(dataset, {EX.S, EX.p1, EX.O2})
      assert RDF.Data.delete(dataset, {EX.S3, EX.p3, EX.O5, EX.NamedGraph}) ==
                Dataset.delete(dataset, {EX.S3, EX.p3, EX.O5, EX.NamedGraph})
      assert RDF.Data.delete(dataset, {EX.Other, EX.p1, EX.O2}) == dataset
    end

    test "deleting a Dataset with a different name does nothing", %{dataset: dataset} do
      assert RDF.Data.delete(dataset,
              %Dataset{dataset | name: EX.OtherDataset}) == dataset
    end

    test "pop", %{dataset: dataset} do
      assert RDF.Data.pop(dataset) == Dataset.pop(dataset)
    end

    test "include?", %{dataset: dataset} do
      assert RDF.Data.include?(dataset, {EX.S, EX.p1, EX.O2})
      assert RDF.Data.include?(dataset, {EX.S2, EX.p2, EX.O3})
      assert RDF.Data.include?(dataset, {EX.S3, EX.p3, EX.O5, EX.NamedGraph})
      refute RDF.Data.include?(dataset, {EX.Other, EX.p1, EX.O2})
    end

    test "description when a description is present",
          %{dataset: dataset, description: description} do
      description_aggregate = Description.add(description, {EX.S, EX.p3, EX.O5})
      assert RDF.Data.description(dataset, uri(EX.S)) == description_aggregate
      assert RDF.Data.description(dataset, EX.S) == description_aggregate
    end

    test "description when a description is not present", %{dataset: dataset} do
      assert RDF.Data.description(dataset, uri(EX.Other)) == Description.new(EX.Other)
    end

    test "descriptions", %{dataset: dataset, description: description} do
      description_aggregate = Description.add(description, {EX.S, EX.p3, EX.O5})
      assert RDF.Data.descriptions(dataset) == [
              description_aggregate,
              (EX.S2 |> EX.p2(EX.O3, EX.O4)),
              (EX.S3 |> EX.p3(EX.O5))
            ]
    end

    test "statements", %{dataset: dataset} do
      assert RDF.Data.statements(dataset) == Dataset.statements(dataset)
    end

    test "subjects", %{dataset: dataset} do
      assert RDF.Data.subjects(dataset) == MapSet.new([uri(EX.S), uri(EX.S2), uri(EX.S3)])
    end

    test "predicates", %{dataset: dataset} do
      assert RDF.Data.predicates(dataset) == MapSet.new([EX.p1, EX.p2, EX.p3])
    end

    test "objects", %{dataset: dataset} do
      assert RDF.Data.objects(dataset) ==
              MapSet.new([uri(EX.O1), uri(EX.O2), uri(EX.O3), uri(EX.O4), uri(EX.O5), ~B<foo>])
    end

    test "resources", %{dataset: dataset} do
      assert RDF.Data.resources(dataset) == MapSet.new([
              uri(EX.S), uri(EX.S2), uri(EX.S3), EX.p1, EX.p2, EX.p3,
              uri(EX.O1), uri(EX.O2), uri(EX.O3), uri(EX.O4), uri(EX.O5), ~B<foo>
             ])
    end

    test "subject_count", %{dataset: dataset} do
      assert RDF.Data.subject_count(dataset) == 3
    end

    test "statement_count", %{dataset: dataset} do
      assert RDF.Data.statement_count(dataset) == 14
    end
  end

end
