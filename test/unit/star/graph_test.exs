defmodule RDF.Star.GraphTest do
  use RDF.Test.Case

  test "new/1" do
    assert Graph.new(init: {statement(), EX.ap(), EX.ao()})
           |> graph_includes_statement?({statement(), EX.ap(), EX.ao()})

    assert Graph.new(init: annotation_description())
           |> graph_includes_statement?({statement(), EX.ap(), EX.ao()})
  end

  describe "add/3" do
    test "with a proper triple as a subject" do
      graph =
        graph()
        |> Graph.add({statement(), EX.ap(), EX.ao1()})
        |> Graph.add({statement(), EX.ap(), EX.ao2()})

      assert graph_includes_statement?(graph, {statement(), EX.ap(), EX.ao1()})
      assert graph_includes_statement?(graph, {statement(), EX.ap(), EX.ao2()})
    end

    test "with a proper triple as a object" do
      graph =
        graph()
        |> Graph.add({EX.as(), EX.ap(), statement()})
        |> Graph.add({EX.as(), EX.ap(), {EX.s(), EX.p(), EX.o2()}})

      assert graph_includes_statement?(graph, {EX.as(), EX.ap(), statement()})
      assert graph_includes_statement?(graph, {EX.as(), EX.ap(), {EX.s(), EX.p(), EX.o2()}})
    end

    test "with a proper triple as a subject and object" do
      assert graph()
             |> Graph.add({statement(), EX.ap(), statement()})
             |> graph_includes_statement?({statement(), EX.ap(), statement()})
    end

    test "with a list of triples" do
      graph =
        Graph.add(graph(), [
          {statement(), EX.ap(), EX.ao()},
          {EX.as(), EX.ap(), statement()},
          {EX.s(), EX.p(), EX.o()}
        ])

      assert graph_includes_statement?(graph, {statement(), EX.ap(), EX.ao()})
      assert graph_includes_statement?(graph, {EX.as(), EX.ap(), statement()})
      assert graph_includes_statement?(graph, {EX.s(), EX.p(), EX.o()})
    end

    test "with a graph map" do
      assert graph()
             |> Graph.add(%{statement() => %{EX.ap() => statement()}})
             |> graph_includes_statement?({statement(), EX.ap(), statement()})
    end

    test "with coercible triples" do
      assert graph()
             |> Graph.add({coercible_statement(), EX.ap(), coercible_statement()})
             |> graph_includes_statement?({statement(), EX.ap(), statement()})
    end
  end

  describe "add/3 with add_annotations option" do
    test "various statement forms annotated with a predicate-object pair" do
      assert Graph.add(graph(), statement(), add_annotations: {EX.AP, EX.AO}) ==
               graph()
               |> Graph.add(statement())
               |> Graph.add({statement(), EX.AP, EX.AO})

      assert Graph.add(graph(), [{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}],
               add_annotations: {EX.AP, EX.AO}
             ) ==
               graph()
               |> Graph.add({EX.S1, EX.P1, EX.O1})
               |> Graph.add({EX.S2, EX.P2, EX.O2})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
               |> Graph.add({{EX.S2, EX.P2, EX.O2}, EX.AP, EX.AO})

      expected_graph =
        graph()
        |> Graph.add({EX.S1, EX.P1, EX.O1})
        |> Graph.add({EX.S1, EX.P1, EX.O2})
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
        |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP, EX.AO})

      assert Graph.add(graph(), {EX.S1, EX.P1, [EX.O1, EX.O2]}, add_annotations: {EX.AP, EX.AO}) ==
               expected_graph

      assert Graph.add(graph(), %{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}},
               add_annotations: {EX.AP, EX.AO}
             ) ==
               expected_graph

      assert Graph.add(graph(), Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
               add_annotations: {EX.AP, EX.AO}
             ) ==
               expected_graph
    end

    test "annotations as a list of predicate-object pairs" do
      assert Graph.add(graph(), statement(), add_annotations: [{EX.AP1, EX.AO1}, {EX.AP2, EX.AO2}]) ==
               graph()
               |> Graph.add(statement())
               |> Graph.add({statement(), EX.AP1, EX.AO1})
               |> Graph.add({statement(), EX.AP2, EX.AO2})
    end

    test "annotations as a description graph" do
      assert Graph.add(graph(), statement(),
               add_annotations: %{EX.AP1 => EX.AO1, EX.AP2 => EX.AO2}
             ) ==
               graph()
               |> Graph.add(statement())
               |> Graph.add({statement(), EX.AP1, EX.AO1})
               |> Graph.add({statement(), EX.AP2, EX.AO2})

      assert Graph.add(graph(), {EX.S1, EX.P1, [EX.O1, EX.O2]},
               add_annotations: %{EX.AP1 => EX.AO1, EX.AP2 => EX.AO2}
             ) ==
               graph()
               |> Graph.add({EX.S1, EX.P1, EX.O1})
               |> Graph.add({EX.S1, EX.P1, EX.O2})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO2})
    end

    test "when annotations exist, they don't get overwritten" do
      assert graph()
             |> Graph.add(statement(), add_annotations: {EX.AP, EX.AO1})
             |> Graph.add(statement(), add_annotations: {EX.AP, EX.AO2}) ==
               graph()
               |> Graph.add(statement())
               |> Graph.add({statement(), EX.AP, [EX.AO1, EX.AO2]})

      expected_graph =
        graph()
        |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]}, add_annotations: {EX.AP1, [EX.AO1, EX.AO2]})

      assert graph()
             |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]}, add_annotations: {EX.AP1, EX.AO1})
             |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]}, add_annotations: {EX.AP1, EX.AO2}) ==
               expected_graph

      assert graph()
             |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]}, add_annotations: {EX.AP1, EX.AO1})
             |> Graph.add(%{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}},
               add_annotations: {EX.AP1, EX.AO2}
             ) ==
               expected_graph

      assert graph()
             |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]}, add_annotations: {EX.AP1, EX.AO1})
             |> Graph.add(
               Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
               add_annotations: {EX.AP1, EX.AO2}
             ) ==
               expected_graph

      assert graph()
             |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
               add_annotations: %{
                 EX.AP1 => EX.AO1,
                 EX.AP2 => EX.AO2
               }
             )
             |> Graph.add(
               {EX.S1, EX.P1, [EX.O1, EX.O2]},
               add_annotations: %{EX.AP3 => EX.AO3, EX.AP2 => EX.AO4}
             ) ==
               graph()
               |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, [EX.AO2, EX.AO4]})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, [EX.AO2, EX.AO4]})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP3, EX.AO3})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP3, EX.AO3})
    end
  end

  test "add/3 with put_annotations option" do
    assert graph()
           |> Graph.add(statement(), add_annotations: {EX.AP1, EX.AO1})
           |> Graph.add(statement(), put_annotations: {EX.AP, EX.AO}) ==
             graph()
             |> Graph.add(statement())
             |> Graph.add({statement(), EX.AP, EX.AO})

    assert graph()
           |> Graph.add_annotations(statement(), {EX.AP1, EX.AO1})
           |> Graph.add(statement(), put_annotations: {EX.AP, EX.AO}) ==
             graph()
             |> Graph.add(statement())
             |> Graph.add({statement(), EX.AP, EX.AO})

    expected_graph =
      graph()
      |> Graph.add({EX.S1, EX.P1, EX.O1})
      |> Graph.add({EX.S1, EX.P1, EX.O2})
      |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO})
      |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO})

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ]
           )
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]}, put_annotations: {EX.AP1, EX.AO}) ==
             expected_graph

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ]
           )
           |> Graph.add(%{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}}, put_annotations: {EX.AP1, EX.AO}) ==
             expected_graph

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ]
           )
           |> Graph.add(
             Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
             put_annotations: {EX.AP1, EX.AO}
           ) ==
             expected_graph

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: %{
               EX.AP1 => EX.AO1,
               EX.AP2 => EX.AO2
             }
           )
           |> Graph.add(
             {EX.S1, EX.P1, [EX.O1, EX.O2]},
             put_annotations: %{EX.AP3 => EX.AO3, EX.AP2 => EX.AO4}
           ) ==
             graph()
             |> Graph.add({EX.S1, EX.P1, EX.O1})
             |> Graph.add({EX.S1, EX.P1, EX.O2})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP3, EX.AO3})
             |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP3, EX.AO3})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO4})
             |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO4})
  end

  test "add/3 with put_annotation_properties option" do
    assert graph()
           |> Graph.add(statement(), add_annotations: {EX.AP1, EX.AO1})
           |> Graph.add(statement(), put_annotation_properties: {EX.AP2, EX.AO2}) ==
             graph()
             |> Graph.add(statement(), add_annotations: [{EX.AP1, EX.AO1}, {EX.AP2, EX.AO2}])

    assert graph()
           |> Graph.add(statement(), add_annotations: {EX.AP, EX.AO1})
           |> Graph.add(statement(), put_annotation_properties: {EX.AP, EX.AO2}) ==
             graph()
             |> Graph.add(statement(), add_annotations: {EX.AP, EX.AO2})

    expected_graph =
      graph()
      |> Graph.add({EX.S1, EX.P1, EX.O1})
      |> Graph.add({EX.S1, EX.P1, EX.O2})
      |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
      |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
      |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
      |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO2})

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ]
           )
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
             put_annotation_properties: {EX.AP1, EX.AO1}
           ) ==
             expected_graph

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ]
           )
           |> Graph.add(
             %{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}},
             put_annotation_properties: {EX.AP1, EX.AO1}
           ) ==
             expected_graph

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ]
           )
           |> Graph.add(
             Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
             put_annotation_properties: {EX.AP1, EX.AO1}
           ) ==
             expected_graph
  end

  describe "put/3" do
    test "with a proper triple as a subject" do
      graph =
        graph()
        |> Graph.put({statement(), EX.ap(), EX.ao1()})
        |> Graph.put({statement(), EX.ap(), EX.ao2()})

      refute graph_includes_statement?(graph, {statement(), EX.ap(), EX.ao1()})
      assert graph_includes_statement?(graph, {statement(), EX.ap(), EX.ao2()})
    end

    test "with a proper triple as a object" do
      graph =
        graph()
        |> Graph.put({EX.as(), EX.ap(), statement()})
        |> Graph.put({EX.as(), EX.ap(), {EX.s(), EX.p(), EX.o2()}})

      refute graph_includes_statement?(graph, {EX.as(), EX.ap(), statement()})
      assert graph_includes_statement?(graph, {EX.as(), EX.ap(), {EX.s(), EX.p(), EX.o2()}})
    end

    test "with a proper triple as a subject and object" do
      assert graph()
             |> Graph.put({statement(), EX.ap(), statement()})
             |> graph_includes_statement?({statement(), EX.ap(), statement()})
    end

    test "with a list of triples" do
      graph =
        Graph.put(graph(), [
          {statement(), EX.ap(), EX.ao()},
          {EX.as(), EX.ap(), statement()},
          {EX.s(), EX.p(), EX.o()}
        ])

      assert graph_includes_statement?(graph, {statement(), EX.ap(), EX.ao()})
      assert graph_includes_statement?(graph, {EX.as(), EX.ap(), statement()})
      assert graph_includes_statement?(graph, {EX.s(), EX.p(), EX.o()})
    end

    test "with a graph map" do
      assert graph()
             |> Graph.put(%{statement() => %{EX.ap() => statement()}})
             |> graph_includes_statement?({statement(), EX.ap(), statement()})
    end

    test "with coercible triples" do
      assert graph()
             |> Graph.put({coercible_statement(), EX.ap(), coercible_statement()})
             |> graph_includes_statement?({statement(), EX.ap(), statement()})
    end
  end

  test "put/3 with add_annotations option" do
    assert graph()
           |> Graph.add(statement(), add_annotations: {EX.AP, EX.AO1})
           |> Graph.put(statement(), add_annotations: {EX.AP, EX.AO2}) ==
             graph()
             |> Graph.add(statement())
             |> Graph.add({statement(), EX.AP, [EX.AO1, EX.AO2]})

    expected_graph =
      graph()
      |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]}, add_annotations: {EX.AP1, [EX.AO1, EX.AO2]})

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]}, add_annotations: {EX.AP1, EX.AO1})
           |> Graph.put({EX.S1, EX.P1, [EX.O1, EX.O2]}, add_annotations: {EX.AP1, EX.AO2}) ==
             expected_graph

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]}, add_annotations: {EX.AP1, EX.AO1})
           |> Graph.put(%{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}},
             add_annotations: {EX.AP1, EX.AO2}
           ) ==
             expected_graph

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]}, add_annotations: {EX.AP1, EX.AO1})
           |> Graph.put(
             Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
             add_annotations: {EX.AP1, EX.AO2}
           ) ==
             expected_graph

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: %{
               EX.AP1 => EX.AO1,
               EX.AP2 => EX.AO2
             }
           )
           |> Graph.put(
             {EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: %{EX.AP3 => EX.AO3, EX.AP2 => EX.AO4}
           ) ==
             graph()
             |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
             |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, [EX.AO2, EX.AO4]})
             |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, [EX.AO2, EX.AO4]})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP3, EX.AO3})
             |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP3, EX.AO3})
  end

  describe "put/3 with put_annotations option" do
    test "with a predicate-object pair" do
      assert Graph.put(graph(), statement(), put_annotations: {EX.AP, EX.AO}) ==
               graph()
               |> Graph.add(statement())
               |> Graph.add({statement(), EX.AP, EX.AO})

      assert Graph.put(graph(), [{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}],
               put_annotations: {EX.AP, EX.AO}
             ) ==
               graph()
               |> Graph.add({EX.S1, EX.P1, EX.O1})
               |> Graph.add({EX.S2, EX.P2, EX.O2})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
               |> Graph.add({{EX.S2, EX.P2, EX.O2}, EX.AP, EX.AO})

      expected_graph =
        graph()
        |> Graph.add({EX.S1, EX.P1, EX.O1})
        |> Graph.add({EX.S1, EX.P1, EX.O2})
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
        |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP, EX.AO})

      assert Graph.put(graph(), {EX.S1, EX.P1, [EX.O1, EX.O2]}, put_annotations: {EX.AP, EX.AO}) ==
               expected_graph

      assert Graph.put(graph(), %{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}},
               put_annotations: {EX.AP, EX.AO}
             ) ==
               expected_graph

      assert Graph.put(graph(), Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
               put_annotations: {EX.AP, EX.AO}
             ) ==
               expected_graph
    end

    test "with multiple annotations" do
      assert Graph.put(graph(), statement(), put_annotations: [{EX.AP1, EX.AO1}, {EX.AP2, EX.AO2}]) ==
               graph()
               |> Graph.add(statement())
               |> Graph.add({statement(), EX.AP1, EX.AO1})
               |> Graph.add({statement(), EX.AP2, EX.AO2})
    end

    test "with a description graph" do
      assert Graph.put(graph(), statement(),
               put_annotations: %{EX.AP1 => EX.AO1, EX.AP2 => EX.AO2}
             ) ==
               graph()
               |> Graph.add(statement())
               |> Graph.add({statement(), EX.AP1, EX.AO1})
               |> Graph.add({statement(), EX.AP2, EX.AO2})

      assert Graph.put(graph(), {EX.S1, EX.P1, [EX.O1, EX.O2]},
               put_annotations: %{EX.AP1 => EX.AO1, EX.AP2 => EX.AO2}
             ) ==
               graph()
               |> Graph.add({EX.S1, EX.P1, EX.O1})
               |> Graph.add({EX.S1, EX.P1, EX.O2})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO2})
    end

    test "with a RDF.Graph" do
      assert Graph.put(graph(), Graph.new({EX.S1, EX.P1, [EX.O1, EX.O2]}),
               put_annotations: %{EX.AP1 => EX.AO1, EX.AP2 => EX.AO2}
             ) ==
               graph()
               |> Graph.add({EX.S1, EX.P1, EX.O1})
               |> Graph.add({EX.S1, EX.P1, EX.O2})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO2})
    end

    test "when an annotation exists" do
      assert graph()
             |> Graph.add(statement(), add_annotations: {EX.AP1, EX.AO1})
             |> Graph.put(statement(), put_annotations: {EX.AP, EX.AO}) ==
               graph()
               |> Graph.add(statement())
               |> Graph.add({statement(), EX.AP, EX.AO})

      base_graph =
        graph()
        |> Graph.add({EX.S1, EX.P1, EX.O1})
        |> Graph.add({EX.S1, EX.P1, EX.O2})

      expected_graph =
        base_graph
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
        |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP, EX.AO})

      assert graph()
             |> Graph.add(base_graph, add_annotations: {EX.AP, EX.AO1})
             |> Graph.put({EX.S1, EX.P1, [EX.O1, EX.O2]}, put_annotations: {EX.AP, EX.AO}) ==
               expected_graph

      assert graph()
             |> Graph.add(base_graph, add_annotations: {EX.AP1, EX.AO})
             |> Graph.put(%{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}}, put_annotations: {EX.AP, EX.AO}) ==
               expected_graph

      assert graph()
             |> Graph.add(base_graph, add_annotations: {EX.AP1, EX.AO1})
             |> Graph.put(Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
               put_annotations: {EX.AP, EX.AO}
             ) ==
               expected_graph

      assert graph()
             |> Graph.add(base_graph, add_annotations: %{EX.AP1 => EX.AO1, EX.AP2 => EX.AO2})
             |> Graph.put({EX.S1, EX.P1, [EX.O1, EX.O2]},
               put_annotations: %{EX.AP3 => EX.AO3, EX.AP2 => EX.AO4}
             ) ==
               graph()
               |> Graph.add({EX.S1, EX.P1, EX.O1})
               |> Graph.add({EX.S1, EX.P1, EX.O2})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP3, EX.AO3})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP3, EX.AO3})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO4})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO4})
    end
  end

  test "put/3 with put_annotation_properties option" do
    assert graph()
           |> Graph.add(statement(), add_annotations: {EX.AP1, EX.AO1})
           |> Graph.put(statement(), put_annotation_properties: {EX.AP2, EX.AO2}) ==
             graph()
             |> Graph.add(statement(), add_annotations: [{EX.AP1, EX.AO1}, {EX.AP2, EX.AO2}])

    assert graph()
           |> Graph.add(statement(), add_annotations: {EX.AP, EX.AO1})
           |> Graph.put(statement(), put_annotation_properties: {EX.AP, EX.AO2}) ==
             graph()
             |> Graph.add(statement(), add_annotations: {EX.AP, EX.AO2})

    expected_graph =
      graph()
      |> Graph.add({EX.S1, EX.P1, EX.O1})
      |> Graph.add({EX.S1, EX.P1, EX.O2})
      |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
      |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
      |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
      |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO2})

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ]
           )
           |> Graph.put({EX.S1, EX.P1, [EX.O1, EX.O2]},
             put_annotation_properties: {EX.AP1, EX.AO1}
           ) ==
             expected_graph

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ]
           )
           |> Graph.put(
             %{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}},
             put_annotation_properties: {EX.AP1, EX.AO1}
           ) ==
             expected_graph

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ]
           )
           |> Graph.put(
             Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
             put_annotation_properties: {EX.AP1, EX.AO1}
           ) ==
             expected_graph
  end

  describe "put/3 with delete_annotations_on_deleted option" do
    test "no annotations of overwritten statements are removed when delete_annotations is false (default)" do
      assert graph()
             |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: [{EX.AP, EX.AO}])
             |> Graph.put({EX.S1, EX.P2, EX.O2}, delete_annotations_on_deleted: false) ==
               graph()
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
               |> Graph.add({EX.S1, EX.P2, EX.O2})

      assert graph()
             |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: [{EX.AP, EX.AO}])
             |> Graph.put({EX.S1, EX.P2, EX.O2}) ==
               graph()
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
               |> Graph.add({EX.S1, EX.P2, EX.O2})
    end

    test "all annotations of overwritten statements are removed when delete_annotations is true" do
      assert graph()
             |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: [{EX.AP, EX.AO}])
             |> Graph.put({EX.S1, EX.P2, EX.O2}, delete_annotations_on_deleted: true) ==
               graph()
               |> Graph.add({EX.S1, EX.P2, EX.O2})

      assert graph()
             |> Graph.add(
               [
                 {EX.S1, EX.P1, EX.O1},
                 {EX.S2, EX.P2, EX.O2}
               ],
               add_annotations: [{EX.AP1, EX.AO1}, {EX.AP2, EX.AO2}]
             )
             |> Graph.put({EX.S1, EX.P3, EX.O3},
               add_annotations: [{EX.AP3, EX.AO3}],
               delete_annotations_on_deleted: true
             ) ==
               graph()
               |> Graph.add([
                 {EX.S1, EX.P3, EX.O3},
                 {{EX.S1, EX.P3, EX.O3}, {EX.AP3, EX.AO3}},
                 {EX.S2, EX.P2, EX.O2},
                 {{EX.S2, EX.P2, EX.O2}, {EX.AP1, EX.AO1}},
                 {{EX.S2, EX.P2, EX.O2}, {EX.AP2, EX.AO2}}
               ])
    end

    test "only the specified annotations of overwritten statements are removed" do
      assert graph()
             |> Graph.add({EX.S1, EX.P1, EX.O1},
               add_annotations: [{EX.AP1, EX.AO1}, {EX.AP2, EX.AO2}]
             )
             |> Graph.put({EX.S1, EX.P2, EX.O2}, delete_annotations_on_deleted: EX.AP1) ==
               graph()
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
               |> Graph.add({EX.S1, EX.P2, EX.O2})
    end
  end

  test "put/3 with add_annotations_on_deleted option" do
    assert graph()
           |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: {EX.AP1, EX.AO1})
           |> Graph.put({EX.S1, EX.P2, EX.O2}, add_annotations_on_deleted: {EX.AP1, EX.AO2}) ==
             graph()
             |> Graph.add({EX.S1, EX.P2, EX.O2})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO2})
  end

  test "put/3 with put_annotations_on_deleted option" do
    assert graph()
           |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: {EX.AP1, EX.AO1})
           |> Graph.put({EX.S1, EX.P2, EX.O2}, put_annotations_on_deleted: {EX.AP2, EX.AO2}) ==
             graph()
             |> Graph.add({EX.S1, EX.P2, EX.O2})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
  end

  test "put/3 with put_annotation_properties_on_deleted option" do
    assert graph()
           |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: {EX.AP1, EX.AO1})
           |> Graph.put({EX.S1, EX.P2, EX.O2},
             put_annotation_properties_on_deleted: [
               {EX.AP1, EX.AO12},
               {EX.AP2, EX.AO2}
             ]
           ) ==
             graph()
             |> Graph.add({EX.S1, EX.P2, EX.O2})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO12})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
  end

  test "put_properties/3" do
    graph =
      graph()
      |> Graph.put_properties({statement(), EX.ap(), EX.ao1()})
      |> Graph.put_properties({statement(), EX.ap(), EX.ao2()})

    refute graph_includes_statement?(graph, {statement(), EX.ap(), EX.ao1()})
    assert graph_includes_statement?(graph, {statement(), EX.ap(), EX.ao2()})

    graph =
      graph()
      |> Graph.put_properties(Graph.new(init: {statement(), EX.ap(), EX.ao1()}))
      |> Graph.put_properties(Graph.new(init: {statement(), EX.ap(), EX.ao2()}))

    refute graph_includes_statement?(graph, {statement(), EX.ap(), EX.ao1()})
    assert graph_includes_statement?(graph, {statement(), EX.ap(), EX.ao2()})
  end

  test "put_properties/3 with add_annotations option" do
    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: %{
               EX.AP1 => EX.AO1,
               EX.AP2 => EX.AO2
             }
           )
           |> Graph.put_properties(
             {EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: %{EX.AP3 => EX.AO3, EX.AP2 => EX.AO4}
           ) ==
             graph()
             |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
             |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, [EX.AO2, EX.AO4]})
             |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, [EX.AO2, EX.AO4]})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP3, EX.AO3})
             |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP3, EX.AO3})
  end

  describe "put_properties/3 with put_annotations option" do
    test "various statement forms annotated with a predicate-object pair" do
      assert Graph.put_properties(graph(), statement(), put_annotations: {EX.AP, EX.AO}) ==
               graph()
               |> Graph.add(statement())
               |> Graph.add({statement(), EX.AP, EX.AO})

      assert Graph.put_properties(graph(), [{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}],
               put_annotations: {EX.AP, EX.AO}
             ) ==
               graph()
               |> Graph.add({EX.S1, EX.P1, EX.O1})
               |> Graph.add({EX.S2, EX.P2, EX.O2})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
               |> Graph.add({{EX.S2, EX.P2, EX.O2}, EX.AP, EX.AO})

      expected_graph =
        graph()
        |> Graph.add({EX.S1, EX.P1, EX.O1})
        |> Graph.add({EX.S1, EX.P1, EX.O2})
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
        |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP, EX.AO})

      assert Graph.put_properties(graph(), {EX.S1, EX.P1, [EX.O1, EX.O2]},
               put_annotations: {EX.AP, EX.AO}
             ) ==
               expected_graph

      assert Graph.put_properties(graph(), %{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}},
               put_annotations: {EX.AP, EX.AO}
             ) ==
               expected_graph

      assert Graph.put_properties(
               graph(),
               Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
               put_annotations: {EX.AP, EX.AO}
             ) ==
               expected_graph
    end

    test "annotations as a list of predicate-object pairs" do
      assert Graph.put_properties(graph(), statement(),
               put_annotations: [{EX.AP1, EX.AO1}, {EX.AP2, EX.AO2}]
             ) ==
               graph()
               |> Graph.add(statement())
               |> Graph.add({statement(), EX.AP1, EX.AO1})
               |> Graph.add({statement(), EX.AP2, EX.AO2})
    end

    test "annotations as a description graph" do
      assert Graph.put_properties(graph(), statement(),
               put_annotations: %{EX.AP1 => EX.AO1, EX.AP2 => EX.AO2}
             ) ==
               graph()
               |> Graph.add(statement())
               |> Graph.add({statement(), EX.AP1, EX.AO1})
               |> Graph.add({statement(), EX.AP2, EX.AO2})

      assert Graph.put_properties(graph(), {EX.S1, EX.P1, [EX.O1, EX.O2]},
               put_annotations: %{EX.AP1 => EX.AO1, EX.AP2 => EX.AO2}
             ) ==
               graph()
               |> Graph.add({EX.S1, EX.P1, EX.O1})
               |> Graph.add({EX.S1, EX.P1, EX.O2})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO2})
    end

    test "annotations as a RDF.Graph" do
      assert Graph.put_properties(graph(), Graph.new({EX.S1, EX.P1, [EX.O1, EX.O2]}),
               put_annotations: %{EX.AP1 => EX.AO1, EX.AP2 => EX.AO2}
             ) ==
               graph()
               |> Graph.add({EX.S1, EX.P1, EX.O1})
               |> Graph.add({EX.S1, EX.P1, EX.O2})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO2})
    end

    test "when annotations exist, they get overwritten" do
      assert graph()
             |> Graph.add(statement(), add_annotations: {EX.AP1, EX.AO1})
             |> Graph.put_properties(statement(), put_annotations: {EX.AP, EX.AO}) ==
               graph()
               |> Graph.add(statement())
               |> Graph.add({statement(), EX.AP, EX.AO})

      assert graph()
             |> Graph.add(statement(), add_annotations: {EX.AP, EX.AO1})
             |> Graph.put_properties(statement(), put_annotations: {EX.AP, EX.AO2}) ==
               graph()
               |> Graph.add(statement())
               |> Graph.add({statement(), EX.AP, EX.AO2})

      base_graph =
        graph()
        |> Graph.add({EX.S1, EX.P1, EX.O1})
        |> Graph.add({EX.S1, EX.P2, EX.O2})

      assert graph()
             |> Graph.add(base_graph, add_annotations: {EX.AP, EX.AO1})
             |> Graph.put_properties({EX.S1, EX.P1, EX.O1}, put_annotations: {EX.AP, EX.AO})
             |> Graph.put_properties({EX.S1, EX.P2, EX.O2}, put_annotations: {EX.AP, EX.AO}) ==
               base_graph
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
               |> Graph.add({{EX.S1, EX.P2, EX.O2}, EX.AP, EX.AO})

      assert graph()
             |> Graph.add(base_graph, add_annotations: {EX.AP1, EX.AO})
             |> Graph.put_properties(%{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}},
               put_annotations: {EX.AP, EX.AO}
             ) ==
               base_graph
               |> Graph.add({EX.S1, EX.P1, EX.O2})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP, EX.AO})
               |> Graph.add({{EX.S1, EX.P2, EX.O2}, EX.AP1, EX.AO})

      assert graph()
             |> Graph.add(base_graph, add_annotations: {EX.AP1, EX.AO1})
             |> Graph.put_properties(Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
               put_annotations: {EX.AP, EX.AO}
             ) ==
               base_graph
               |> Graph.add({EX.S1, EX.P1, EX.O2})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP, EX.AO})
               |> Graph.add({{EX.S1, EX.P2, EX.O2}, EX.AP1, EX.AO1})

      assert graph()
             |> Graph.add(base_graph, add_annotations: %{EX.AP1 => EX.AO1, EX.AP2 => EX.AO2})
             |> Graph.put_properties({EX.S1, EX.P1, EX.O2},
               put_annotations: %{EX.AP3 => EX.AO3, EX.AP2 => EX.AO4}
             ) ==
               graph()
               |> Graph.add({EX.S1, EX.P1, EX.O2})
               |> Graph.add({EX.S1, EX.P2, EX.O2})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP3, EX.AO3})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO4})
               |> Graph.add({{EX.S1, EX.P2, EX.O2}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P2, EX.O2}, EX.AP2, EX.AO2})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
    end
  end

  test "put_properties/3 with put_annotation_properties option" do
    assert graph()
           |> Graph.add(statement(), add_annotations: {EX.AP1, EX.AO1})
           |> Graph.put_properties(statement(), put_annotation_properties: {EX.AP2, EX.AO2}) ==
             graph()
             |> Graph.add(statement(), add_annotations: [{EX.AP1, EX.AO1}, {EX.AP2, EX.AO2}])

    assert graph()
           |> Graph.add(statement(), add_annotations: {EX.AP, EX.AO1})
           |> Graph.put_properties(statement(), put_annotation_properties: %{EX.AP => EX.AO2}) ==
             graph()
             |> Graph.add(statement(), add_annotations: {EX.AP, EX.AO2})

    expected_graph =
      graph()
      |> Graph.add({EX.S1, EX.P1, EX.O1})
      |> Graph.add({EX.S1, EX.P1, EX.O2})
      |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
      |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
      |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
      |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO2})

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ]
           )
           |> Graph.put_properties({EX.S1, EX.P1, [EX.O1, EX.O2]},
             put_annotation_properties: {EX.AP1, EX.AO1}
           ) ==
             expected_graph

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ]
           )
           |> Graph.put_properties(
             %{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}},
             put_annotation_properties: {EX.AP1, EX.AO1}
           ) ==
             expected_graph

    assert graph()
           |> Graph.add({EX.S1, EX.P1, [EX.O1, EX.O2]},
             add_annotations: [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ]
           )
           |> Graph.put_properties(
             Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
             put_annotation_properties: {EX.AP1, EX.AO1}
           ) ==
             expected_graph
  end

  describe "put_properties/3 with delete_annotations_on_deleted option" do
    test "no annotations of overwritten statements are removed when delete_annotations is false (default)" do
      assert graph()
             |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: [{EX.AP, EX.AO}])
             |> Graph.put_properties({EX.S1, EX.P1, EX.O2}, delete_annotations_on_deleted: false) ==
               graph()
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
               |> Graph.add({EX.S1, EX.P1, EX.O2})

      assert graph()
             |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: [{EX.AP, EX.AO}])
             |> Graph.put_properties({EX.S1, EX.P1, EX.O2}) ==
               graph()
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
               |> Graph.add({EX.S1, EX.P1, EX.O2})
    end

    test "all annotations of overwritten statements are removed when delete_annotations is true" do
      assert graph()
             |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: [{EX.AP, EX.AO}])
             |> Graph.put_properties({EX.S1, EX.P1, EX.O2}, delete_annotations_on_deleted: true) ==
               graph()
               |> Graph.add({EX.S1, EX.P1, EX.O2})

      assert graph()
             |> Graph.add(
               [
                 {EX.S1, EX.P1, EX.O1},
                 {EX.S2, EX.P2, EX.O2}
               ],
               add_annotations: [{EX.AP1, EX.AO1}, {EX.AP2, EX.AO2}]
             )
             |> Graph.put_properties({EX.S1, EX.P1, EX.O3},
               add_annotations: [{EX.AP3, EX.AO3}],
               delete_annotations_on_deleted: true
             ) ==
               graph()
               |> Graph.add([
                 {EX.S1, EX.P1, EX.O3},
                 {{EX.S1, EX.P1, EX.O3}, {EX.AP3, EX.AO3}},
                 {EX.S2, EX.P2, EX.O2},
                 {{EX.S2, EX.P2, EX.O2}, {EX.AP1, EX.AO1}},
                 {{EX.S2, EX.P2, EX.O2}, {EX.AP2, EX.AO2}}
               ])
    end

    test "only the specified annotations of overwritten statements are removed" do
      assert graph()
             |> Graph.add({EX.S1, EX.P1, EX.O1},
               add_annotations: [{EX.AP1, EX.AO1}, {EX.AP2, EX.AO2}]
             )
             |> Graph.put_properties({EX.S1, EX.P1, EX.O2}, delete_annotations_on_deleted: EX.AP1) ==
               graph()
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
               |> Graph.add({EX.S1, EX.P1, EX.O2})
    end
  end

  test "put_properties/3 with add_annotations_on_deleted option" do
    assert graph()
           |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: {EX.AP1, EX.AO1})
           |> Graph.put_properties({EX.S1, EX.P1, EX.O2},
             add_annotations_on_deleted: {EX.AP1, EX.AO2}
           ) ==
             graph()
             |> Graph.add({EX.S1, EX.P1, EX.O2})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO2})
  end

  test "put_properties/3 with put_annotations_on_deleted option" do
    assert graph()
           |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: {EX.AP1, EX.AO1})
           |> Graph.put_properties({EX.S1, EX.P1, EX.O2},
             put_annotations_on_deleted: {EX.AP2, EX.AO2}
           ) ==
             graph()
             |> Graph.add({EX.S1, EX.P1, EX.O2})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
  end

  test "put_properties/3 with put_annotation_properties_on_deleted option" do
    assert graph()
           |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: {EX.AP1, EX.AO1})
           |> Graph.put_properties({EX.S1, EX.P1, EX.O2},
             put_annotation_properties_on_deleted: [
               {EX.AP1, EX.AO12},
               {EX.AP2, EX.AO2}
             ]
           ) ==
             graph()
             |> Graph.add({EX.S1, EX.P1, EX.O2})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO12})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
  end

  test "delete/3" do
    assert graph_with_annotation() |> Graph.delete(star_statement()) == graph()
  end

  describe "delete/3 with delete_annotations option" do
    test "with false, no annotations are deleted (default)" do
      assert graph()
             |> Graph.add(statement(), add_annotations: {EX.p(), EX.O})
             |> Graph.delete(statement(), delete_annotations: false) ==
               graph() |> Graph.add({statement(), EX.p(), EX.O})

      assert graph()
             |> Graph.add(statement(), add_annotations: {EX.p(), EX.O})
             |> Graph.delete(statement()) ==
               graph() |> Graph.add({statement(), EX.p(), EX.O})
    end

    test "with true, all annotations are deleted" do
      assert graph()
             |> Graph.add(statement(), add_annotations: {EX.p(), EX.O})
             |> Graph.delete(statement(), delete_annotations: true) ==
               graph()
    end

    test "annotations are even deleted, when the statements to be deleted are not present" do
      assert graph_with_annotation() |> Graph.delete(statement(), delete_annotations: true) ==
               graph()
    end

    test "with predicates" do
      graph =
        graph()
        |> Graph.add({EX.S1, EX.P1, EX.O1})
        |> Graph.add({EX.S2, EX.P2, EX.O2})
        |> Graph.add({EX.S3, EX.P3, EX.O3})
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, [EX.AO1, EX.AO2]})
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO})
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP3, EX.AO})
        |> Graph.add({{EX.S2, EX.P3, EX.O3}, EX.AP1, EX.AO})
        |> Graph.add({{EX.S3, EX.P3, EX.O3}, EX.AP1, EX.AO})

      assert Graph.delete(
               graph,
               [{EX.S1, EX.P1, EX.O1}, {EX.S3, EX.P3, EX.O3}],
               delete_annotations: [EX.AP1, EX.AP2]
             ) ==
               graph()
               |> Graph.add({EX.S2, EX.P2, EX.O2})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP3, EX.AO})
               |> Graph.add({{EX.S2, EX.P3, EX.O3}, EX.AP1, EX.AO})

      graph =
        graph()
        |> Graph.add(%{EX.S1 => %{EX.P1 => EX.O1, EX.P2 => EX.O2}},
          add_annotations: %{EX.AP1 => EX.AO1}
        )

      assert Graph.delete(graph, {EX.S1, %{EX.P1 => EX.O1}}, delete_annotations: [EX.AP1, EX.AP2]) ==
               graph()
               |> Graph.add({EX.S1, EX.P2, EX.O2})
               |> Graph.add({{EX.S1, EX.P2, EX.O2}, EX.AP1, EX.AO1})
    end
  end

  test "delete/3 with add_annotations option" do
    assert graph()
           |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: {EX.AP1, EX.AO1})
           |> Graph.delete({EX.S1, EX.P1, EX.O1},
             add_annotations: {EX.AP1, EX.AO2}
           ) ==
             graph()
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO2})
  end

  test "delete/3 with put_annotations option" do
    assert graph()
           |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: {EX.AP1, EX.AO1})
           |> Graph.delete({EX.S1, EX.P1, EX.O1},
             put_annotations: {EX.AP2, EX.AO2}
           ) ==
             graph()
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
  end

  test "delete/3 with put_annotation_properties option" do
    assert graph()
           |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: {EX.AP1, EX.AO1})
           |> Graph.delete({EX.S1, EX.P1, EX.O1},
             put_annotation_properties: [
               {EX.AP1, EX.AO12},
               {EX.AP2, EX.AO2}
             ]
           ) ==
             graph()
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO12})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
  end

  test "delete_descriptions/3" do
    assert graph_with_annotation() |> Graph.delete_descriptions(statement()) == graph()
  end

  describe "delete_descriptions/3 with delete_annotations option" do
    test "with false, no annotations are deleted (default)" do
      assert graph()
             |> Graph.add(statement(), add_annotations: {EX.p(), EX.O})
             |> Graph.delete_descriptions(EX.S, delete_annotations: false) ==
               graph() |> Graph.add({statement(), EX.p(), EX.O})

      assert graph()
             |> Graph.add(statement(), add_annotations: {EX.p(), EX.O})
             |> Graph.delete_descriptions(EX.S) ==
               graph() |> Graph.add({statement(), EX.p(), EX.O})
    end

    test "with true, all annotations are deleted" do
      assert graph()
             |> Graph.add(statement(), add_annotations: {EX.p(), EX.O})
             |> Graph.delete_descriptions(EX.S, delete_annotations: true) ==
               graph()
    end

    test "with predicates" do
      graph =
        graph()
        |> Graph.add({EX.S1, EX.P1, EX.O1})
        |> Graph.add({EX.S2, EX.P2, EX.O2})
        |> Graph.add({EX.S3, EX.P3, EX.O3})
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, [EX.AO1, EX.AO2]})
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO})
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP3, EX.AO})
        |> Graph.add({{EX.S2, EX.P3, EX.O3}, EX.AP1, EX.AO})
        |> Graph.add({{EX.S3, EX.P3, EX.O3}, EX.AP1, EX.AO})

      assert Graph.delete_descriptions(graph, [EX.S1, EX.S3], delete_annotations: [EX.AP1, EX.AP2]) ==
               graph()
               |> Graph.add({EX.S2, EX.P2, EX.O2})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP3, EX.AO})
               |> Graph.add({{EX.S2, EX.P3, EX.O3}, EX.AP1, EX.AO})
    end
  end

  test "delete_descriptions/3 with add_annotations option" do
    assert graph()
           |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: {EX.AP1, EX.AO1})
           |> Graph.delete_descriptions(EX.S1, add_annotations: {EX.AP1, EX.AO2}) ==
             graph()
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO2})
  end

  test "delete_descriptions/3 with put_annotations option" do
    assert graph()
           |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: {EX.AP1, EX.AO1})
           |> Graph.delete_descriptions(EX.S1, put_annotations: {EX.AP2, EX.AO2}) ==
             graph()
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
  end

  test "delete_descriptions/3 with put_annotation_properties option" do
    assert graph()
           |> Graph.add({EX.S1, EX.P1, EX.O1}, add_annotations: {EX.AP1, EX.AO1})
           |> Graph.delete_descriptions(EX.S1,
             put_annotation_properties: [
               {EX.AP1, EX.AO12},
               {EX.AP2, EX.AO2}
             ]
           ) ==
             graph()
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO12})
             |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
  end

  describe "add_annotations/3" do
    test "various statement forms annotated with a predicate-object pair" do
      assert Graph.add_annotations(graph(), statement(), {EX.AP, EX.AO}) ==
               graph()
               |> Graph.add({statement(), EX.AP, EX.AO})

      expected_graph =
        graph()
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
        |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP, EX.AO})

      assert Graph.add_annotations(graph(), {EX.S1, EX.P1, [EX.O1, EX.O2]}, {EX.AP, EX.AO}) ==
               expected_graph

      assert Graph.add_annotations(
               graph(),
               %{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}},
               {EX.AP, EX.AO}
             ) ==
               expected_graph

      assert Graph.add_annotations(
               graph(),
               Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
               {EX.AP, EX.AO}
             ) ==
               expected_graph

      assert Graph.add_annotations(
               graph(),
               Graph.new(%{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}}),
               {EX.AP, EX.AO}
             ) ==
               expected_graph
    end

    test "annotations as a list of predicate-object pairs" do
      assert Graph.add_annotations(graph(), statement(), [{EX.AP1, EX.AO1}, {EX.AP2, EX.AO2}]) ==
               graph()
               |> Graph.add({statement(), EX.AP1, EX.AO1})
               |> Graph.add({statement(), EX.AP2, EX.AO2})
    end

    test "annotations as a description graph" do
      assert Graph.add_annotations(graph(), statement(), %{EX.AP1 => EX.AO1, EX.AP2 => EX.AO2}) ==
               graph()
               |> Graph.add({statement(), EX.AP1, EX.AO1})
               |> Graph.add({statement(), EX.AP2, EX.AO2})

      assert Graph.add_annotations(graph(), {EX.S1, EX.P1, [EX.O1, EX.O2]}, %{
               EX.AP1 => EX.AO1,
               EX.AP2 => EX.AO2
             }) ==
               graph()
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO2})
    end

    test "annotations as a RDF.Graph" do
      assert Graph.add_annotations(graph(), Graph.new({EX.S1, EX.P1, [EX.O1, EX.O2]}), %{
               EX.AP1 => EX.AO1,
               EX.AP2 => EX.AO2
             }) ==
               graph()
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO2})
    end

    test "when annotations exist, they don't get overwritten" do
      assert graph()
             |> Graph.add_annotations(statement(), {EX.AP, EX.AO1})
             |> Graph.add_annotations(statement(), {EX.AP, EX.AO2}) ==
               graph()
               |> Graph.add({statement(), EX.AP, [EX.AO1, EX.AO2]})

      expected_graph =
        graph()
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, [EX.AO1, EX.AO2]})
        |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, [EX.AO1, EX.AO2]})

      assert graph()
             |> Graph.add_annotations({EX.S1, EX.P1, [EX.O1, EX.O2]}, {EX.AP1, EX.AO1})
             |> Graph.add_annotations({EX.S1, EX.P1, [EX.O1, EX.O2]}, {EX.AP1, EX.AO2}) ==
               expected_graph

      assert graph()
             |> Graph.add_annotations({EX.S1, EX.P1, [EX.O1, EX.O2]}, {EX.AP1, EX.AO1})
             |> Graph.add_annotations(%{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}}, {EX.AP1, EX.AO2}) ==
               expected_graph

      assert graph()
             |> Graph.add_annotations({EX.S1, EX.P1, [EX.O1, EX.O2]}, {EX.AP1, EX.AO1})
             |> Graph.add_annotations(
               Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
               {EX.AP1, EX.AO2}
             ) ==
               expected_graph

      assert graph()
             |> Graph.add_annotations({EX.S1, EX.P1, [EX.O1, EX.O2]}, %{
               EX.AP1 => EX.AO1,
               EX.AP2 => EX.AO2
             })
             |> Graph.add_annotations(
               {EX.S1, EX.P1, [EX.O1, EX.O2]},
               %{EX.AP3 => EX.AO3, EX.AP2 => EX.AO4}
             ) ==
               graph()
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, [EX.AO2, EX.AO4]})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, [EX.AO2, EX.AO4]})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP3, EX.AO3})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP3, EX.AO3})
    end
  end

  describe "put_annotations/3" do
    test "various statement forms annotated with a predicate-object pair" do
      assert Graph.put_annotations(graph(), statement(), {EX.AP, EX.AO}) ==
               graph()
               |> Graph.add({statement(), EX.AP, EX.AO})

      assert Graph.put_annotations(
               graph(),
               [{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}],
               {EX.AP, EX.AO}
             ) ==
               graph()
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
               |> Graph.add({{EX.S2, EX.P2, EX.O2}, EX.AP, EX.AO})

      expected_graph =
        graph()
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
        |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP, EX.AO})

      assert Graph.put_annotations(graph(), {EX.S1, EX.P1, [EX.O1, EX.O2]}, {EX.AP, EX.AO}) ==
               expected_graph

      assert Graph.put_annotations(
               graph(),
               %{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}},
               {EX.AP, EX.AO}
             ) ==
               expected_graph

      assert Graph.put_annotations(
               graph(),
               Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
               {EX.AP, EX.AO}
             ) ==
               expected_graph
    end

    test "annotations as a list of predicate-object pairs" do
      assert Graph.put_annotations(graph(), statement(), [{EX.AP1, EX.AO1}, {EX.AP2, EX.AO2}]) ==
               graph()
               |> Graph.add({statement(), EX.AP1, EX.AO1})
               |> Graph.add({statement(), EX.AP2, EX.AO2})
    end

    test "annotations as a description graph" do
      assert Graph.put_annotations(graph(), statement(), %{EX.AP1 => EX.AO1, EX.AP2 => EX.AO2}) ==
               graph()
               |> Graph.add({statement(), EX.AP1, EX.AO1})
               |> Graph.add({statement(), EX.AP2, EX.AO2})

      assert Graph.put_annotations(graph(), {EX.S1, EX.P1, [EX.O1, EX.O2]}, %{
               EX.AP1 => EX.AO1,
               EX.AP2 => EX.AO2
             }) ==
               graph()
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO2})
    end

    test "annotations as a RDF.Graph" do
      assert Graph.put_annotations(graph(), Graph.new({EX.S1, EX.P1, [EX.O1, EX.O2]}), %{
               EX.AP1 => EX.AO1,
               EX.AP2 => EX.AO2
             }) ==
               graph()
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO2})
    end

    test "when annotations exist, they get overwritten" do
      assert graph()
             |> Graph.add_annotations(statement(), {EX.AP1, EX.AO1})
             |> Graph.put_annotations(statement(), {EX.AP, EX.AO}) ==
               graph()
               |> Graph.add({statement(), EX.AP, EX.AO})

      expected_graph =
        graph()
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO})
        |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO})

      assert graph()
             |> Graph.add_annotations({EX.S1, EX.P1, [EX.O1, EX.O2]}, [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ])
             |> Graph.put_annotations({EX.S1, EX.P1, [EX.O1, EX.O2]}, {EX.AP1, EX.AO}) ==
               expected_graph

      assert graph()
             |> Graph.add_annotations({EX.S1, EX.P1, [EX.O1, EX.O2]}, [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ])
             |> Graph.put_annotations(%{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}}, {EX.AP1, EX.AO}) ==
               expected_graph

      assert graph()
             |> Graph.add_annotations({EX.S1, EX.P1, [EX.O1, EX.O2]}, [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ])
             |> Graph.put_annotations(
               Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
               {EX.AP1, EX.AO}
             ) ==
               expected_graph

      assert graph()
             |> Graph.add_annotations({EX.S1, EX.P1, [EX.O1, EX.O2]}, %{
               EX.AP1 => EX.AO1,
               EX.AP2 => EX.AO2
             })
             |> Graph.put_annotations(
               {EX.S1, EX.P1, [EX.O1, EX.O2]},
               %{EX.AP3 => EX.AO3, EX.AP2 => EX.AO4}
             ) ==
               graph()
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP3, EX.AO3})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP3, EX.AO3})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO4})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO4})
    end
  end

  describe "put_annotation_properties/3" do
    test "various statement forms annotated with a predicate-object pair" do
      assert Graph.put_annotation_properties(graph(), statement(), {EX.AP, EX.AO}) ==
               graph()
               |> Graph.add({statement(), EX.AP, EX.AO})

      assert Graph.put_annotation_properties(
               graph(),
               [{EX.S1, EX.P1, EX.O1}, {EX.S2, EX.P2, EX.O2}],
               {EX.AP, EX.AO}
             ) ==
               graph()
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
               |> Graph.add({{EX.S2, EX.P2, EX.O2}, EX.AP, EX.AO})

      expected_graph =
        graph()
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
        |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP, EX.AO})

      assert Graph.put_annotation_properties(
               graph(),
               {EX.S1, EX.P1, [EX.O1, EX.O2]},
               {EX.AP, EX.AO}
             ) ==
               expected_graph

      assert Graph.put_annotation_properties(
               graph(),
               %{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}},
               {EX.AP, EX.AO}
             ) ==
               expected_graph

      assert Graph.put_annotation_properties(
               graph(),
               Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
               {EX.AP, EX.AO}
             ) ==
               expected_graph
    end

    test "annotations as a list of predicate-object pairs" do
      assert Graph.put_annotation_properties(graph(), statement(), [
               {EX.AP1, EX.AO1},
               {EX.AP2, EX.AO2}
             ]) ==
               graph()
               |> Graph.add({statement(), EX.AP1, EX.AO1})
               |> Graph.add({statement(), EX.AP2, EX.AO2})
    end

    test "annotations as a description graph" do
      assert Graph.put_annotation_properties(graph(), statement(), %{
               EX.AP1 => EX.AO1,
               EX.AP2 => EX.AO2
             }) ==
               graph()
               |> Graph.add({statement(), EX.AP1, EX.AO1})
               |> Graph.add({statement(), EX.AP2, EX.AO2})

      assert Graph.put_annotation_properties(graph(), {EX.S1, EX.P1, [EX.O1, EX.O2]}, %{
               EX.AP1 => EX.AO1,
               EX.AP2 => EX.AO2
             }) ==
               graph()
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO2})
    end

    test "annotations as a RDF.Graph" do
      assert Graph.put_annotation_properties(
               graph(),
               Graph.new({EX.S1, EX.P1, [EX.O1, EX.O2]}),
               %{
                 EX.AP1 => EX.AO1,
                 EX.AP2 => EX.AO2
               }
             ) ==
               graph()
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
               |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO2})
    end

    test "when annotations exist, only the given properties get overwritten" do
      assert graph()
             |> Graph.add_annotations(statement(), {EX.AP1, EX.AO1})
             |> Graph.put_annotation_properties(statement(), {EX.AP2, EX.AO2}) ==
               graph()
               |> Graph.add({statement(), EX.AP1, EX.AO1})
               |> Graph.add({statement(), EX.AP2, EX.AO2})

      assert graph()
             |> Graph.add_annotations(statement(), {EX.AP, EX.AO1})
             |> Graph.put_annotation_properties(statement(), {EX.AP, EX.AO2}) ==
               graph()
               |> Graph.add({statement(), EX.AP, EX.AO2})

      expected_graph =
        graph()
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, EX.AO1})
        |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP1, EX.AO1})
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO2})
        |> Graph.add({{EX.S1, EX.P1, EX.O2}, EX.AP2, EX.AO2})

      assert graph()
             |> Graph.add_annotations({EX.S1, EX.P1, [EX.O1, EX.O2]}, [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ])
             |> Graph.put_annotation_properties({EX.S1, EX.P1, [EX.O1, EX.O2]}, {EX.AP1, EX.AO1}) ==
               expected_graph

      assert graph()
             |> Graph.add_annotations({EX.S1, EX.P1, [EX.O1, EX.O2]}, [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ])
             |> Graph.put_annotation_properties(
               %{EX.S1 => %{EX.P1 => [EX.O1, EX.O2]}},
               {EX.AP1, EX.AO1}
             ) ==
               expected_graph

      assert graph()
             |> Graph.add_annotations({EX.S1, EX.P1, [EX.O1, EX.O2]}, [
               {EX.AP1, EX.AO},
               {EX.AP2, EX.AO2}
             ])
             |> Graph.put_annotation_properties(
               Description.new(EX.S1, init: %{EX.P1 => [EX.O1, EX.O2]}),
               {EX.AP1, EX.AO1}
             ) ==
               expected_graph
    end
  end

  describe "delete_annotations/3" do
    test "with false, no annotations are deleted" do
      graph = Graph.add(graph(), statement(), add_annotations: {EX.p(), EX.O})
      assert Graph.delete_annotations(graph, statement(), false) == graph
    end

    test "with true, all annotations are deleted (default)" do
      assert graph()
             |> Graph.add(statement(), add_annotations: {EX.p(), EX.O})
             |> Graph.delete_annotations(statement(), true) ==
               graph() |> Graph.add(statement())

      assert graph()
             |> Graph.add(statement(), add_annotations: {EX.p(), EX.O})
             |> Graph.delete_annotations(statement()) ==
               graph() |> Graph.add(statement())
    end

    test "with a single predicate" do
      assert graph()
             |> Graph.add(statement(), add_annotations: [{EX.p1(), EX.O1}, {EX.p2(), EX.O2}])
             |> Graph.delete_annotations(statement(), EX.p2()) ==
               Graph.add(graph(), statement(), add_annotations: {EX.p1(), EX.O1})

      graph =
        graph()
        |> Graph.add({EX.S1, EX.P1, EX.O1})
        |> Graph.add({EX.S2, EX.P2, EX.O2})
        |> Graph.add({EX.S3, EX.P3, EX.O3})
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP, EX.AO})
        |> Graph.add({{EX.S3, EX.P3, EX.O3}, EX.AP, EX.AO})

      assert Graph.delete_annotations(
               graph,
               [{EX.S1, EX.P1, EX.O1}, {EX.S3, EX.P3, EX.O3}],
               EX.AP
             ) ==
               graph()
               |> Graph.add({EX.S1, EX.P1, EX.O1})
               |> Graph.add({EX.S2, EX.P2, EX.O2})
               |> Graph.add({EX.S3, EX.P3, EX.O3})
    end

    test "with a list of predicates" do
      graph =
        graph()
        |> Graph.add({EX.S1, EX.P1, EX.O1})
        |> Graph.add({EX.S2, EX.P2, EX.O2})
        |> Graph.add({EX.S3, EX.P3, EX.O3})
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP1, [EX.AO1, EX.AO2]})
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP2, EX.AO})
        |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP3, EX.AO})
        |> Graph.add({{EX.S2, EX.P3, EX.O3}, EX.AP1, EX.AO})
        |> Graph.add({{EX.S3, EX.P3, EX.O3}, EX.AP1, EX.AO})

      assert Graph.delete_annotations(
               graph,
               [{EX.S1, EX.P1, EX.O1}, {EX.S3, EX.P3, EX.O3}],
               [EX.AP1, EX.AP2]
             ) ==
               graph()
               |> Graph.add({EX.S1, EX.P1, EX.O1})
               |> Graph.add({EX.S2, EX.P2, EX.O2})
               |> Graph.add({EX.S3, EX.P3, EX.O3})
               |> Graph.add({{EX.S1, EX.P1, EX.O1}, EX.AP3, EX.AO})
               |> Graph.add({{EX.S2, EX.P3, EX.O3}, EX.AP1, EX.AO})
    end
  end

  test "update/3" do
    assert Graph.update(graph(), statement(), annotation_description(), fn _ ->
             raise "unexpected"
           end) ==
             graph_with_annotation()

    assert graph()
           |> Graph.add({statement(), EX.foo(), EX.bar()})
           |> Graph.update(statement(), fn _ -> annotation_description() end) ==
             graph_with_annotation()
  end

  test "fetch/2" do
    assert graph_with_annotation() |> Graph.fetch(statement()) == {:ok, annotation_description()}
  end

  test "get/3" do
    assert graph_with_annotation() |> Graph.get(statement()) == annotation_description()
  end

  test "get_and_update/3" do
    assert Graph.get_and_update(graph_with_annotation(), statement(), fn description ->
             {description, description_with_quoted_triple_object()}
           end) ==
             {annotation_description(), Graph.new(init: {statement(), EX.ap(), statement()})}
  end

  test "pop/2" do
    assert Graph.pop(graph_with_annotation(), statement()) == {annotation_description(), graph()}
  end

  test "subject_count/1" do
    assert Graph.subject_count(graph_with_quoted_triples()) == 2
  end

  test "subjects/1" do
    assert Graph.subjects(graph_with_quoted_triples()) ==
             MapSet.new([statement(), RDF.iri(EX.As)])
  end

  test "objects/1" do
    assert Graph.objects(graph_with_quoted_triples()) == MapSet.new([statement(), EX.ao()])
  end

  describe "statements/1" do
    test "without the filter_star flag" do
      assert Graph.statements(graph_with_quoted_triples()) == [
               star_statement(),
               {RDF.iri(EX.As), EX.ap(), statement()}
             ]
    end

    test "with the filter_star flag" do
      assert Graph.statements(graph_with_quoted_triples(), filter_star: true) == []
      assert Graph.triples(graph_with_quoted_triples(), filter_star: true) == []

      assert Graph.new(
               init: [
                 {statement(), EX.ap(), EX.ao()},
                 {statement(), EX.ap(), statement()},
                 {EX.s(), EX.p(), EX.o()},
                 {EX.s(), EX.ap(), statement()}
               ]
             )
             |> Graph.statements(filter_star: true) == [{EX.s(), EX.p(), EX.o()}]
    end
  end

  describe "annotations/1" do
    test "when no annotations exist" do
      assert Graph.annotations(RDF.graph()) == RDF.graph()
      assert Graph.annotations(RDF.graph(statement())) == RDF.graph()
    end

    test "when annotations exist" do
      assert Graph.annotations(graph_with_annotation()) == graph_with_annotation()

      assert graph_with_annotation()
             |> Graph.add(statement())
             |> Graph.annotations() == graph_with_annotation()
    end
  end

  describe "without_annotations/1" do
    test "when no annotations exist" do
      assert Graph.without_annotations(RDF.graph()) == RDF.graph()
      assert Graph.without_annotations(RDF.graph(statement())) == RDF.graph(statement())
    end

    test "when annotations exist" do
      assert Graph.without_annotations(graph_with_annotation()) == RDF.graph()

      assert graph_with_annotation()
             |> Graph.add(statement())
             |> Graph.without_annotations() == RDF.graph(statement())
    end

    test "quoted triples on object position" do
      assert Graph.without_annotations(graph_with_quoted_triples()) ==
               RDF.graph(description_with_quoted_triple_object())

      assert graph_with_quoted_triples()
             |> Graph.add(statement())
             |> Graph.without_annotations() ==
               RDF.graph([statement(), description_with_quoted_triple_object()])
    end
  end

  describe "without_quoted_triples/1" do
    test "when no annotations exist" do
      assert Graph.without_quoted_triples(RDF.graph()) == RDF.graph()
      assert Graph.without_quoted_triples(RDF.graph(statement())) == RDF.graph(statement())
    end

    test "when annotations exist" do
      assert Graph.without_quoted_triples(graph_with_annotation()) == RDF.graph()

      assert graph_with_annotation()
             |> Graph.add(statement())
             |> Graph.without_quoted_triples() == RDF.graph(statement())
    end

    test "quoted triples on object position" do
      assert Graph.without_quoted_triples(graph_with_quoted_triples()) == RDF.graph()

      assert graph_with_quoted_triples()
             |> Graph.add(statement())
             |> Graph.without_quoted_triples() == RDF.graph(statement())
    end
  end

  test "include?/3" do
    assert Graph.include?(graph_with_quoted_triples(), star_statement())
    assert Graph.include?(graph_with_quoted_triples(), {EX.As, EX.ap(), statement()})
  end

  test "describes?/2" do
    assert Graph.describes?(graph_with_quoted_triples(), statement())
  end

  test "values/2" do
    assert graph_with_quoted_triples() |> Graph.values() == %{}

    assert Graph.new(
             init: [
               annotation_description(),
               {EX.s(), EX.p(), ~L"Foo"},
               {EX.s(), EX.ap(), statement()}
             ]
           )
           |> Graph.values() ==
             %{RDF.Term.value(EX.s()) => %{RDF.Term.value(EX.p()) => ["Foo"]}}
  end

  test "map/2" do
    mapping = fn
      {:predicate, predicate} ->
        predicate |> to_string() |> String.split("/") |> List.last() |> String.to_atom()

      {_, term} ->
        RDF.Term.value(term)
    end

    assert graph_with_quoted_triples() |> Graph.map(mapping) == %{}

    assert Graph.new([
             annotation_description(),
             {EX.s1(), EX.p(), EX.o1()},
             {EX.s2(), EX.p(), EX.o2()},
             description_with_quoted_triple_object()
           ])
           |> Graph.map(mapping) ==
             %{
               RDF.Term.value(EX.s1()) => %{p: [RDF.Term.value(EX.o1())]},
               RDF.Term.value(EX.s2()) => %{p: [RDF.Term.value(EX.o2())]}
             }
  end
end
