defmodule RDF.Star.Graph.Test do
  use RDF.Test.Case

  test "new/1" do
    assert Graph.new(init: {statement(), EX.ap(), EX.ao()})
           |> graph_includes_statement?({statement(), EX.ap(), EX.ao()})

    assert Graph.new(init: annotation())
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

  test "delete/3" do
    assert graph_with_annotation() |> Graph.delete(star_statement()) == graph()
  end

  test "delete_description/3" do
    assert graph_with_annotation() |> Graph.delete_descriptions(statement()) == graph()
  end

  test "update/3" do
    assert Graph.update(graph(), statement(), annotation(), fn _ -> raise "unexpected" end) ==
             graph_with_annotation()

    assert graph()
           |> Graph.add({statement(), EX.foo(), EX.bar()})
           |> Graph.update(statement(), fn _ -> annotation() end) ==
             graph_with_annotation()
  end

  test "fetch/2" do
    assert graph_with_annotation() |> Graph.fetch(statement()) == {:ok, annotation()}
  end

  test "get/3" do
    assert graph_with_annotation() |> Graph.get(statement()) == annotation()
  end

  test "get_and_update/3" do
    assert Graph.get_and_update(graph_with_annotation(), statement(), fn description ->
             {description, object_annotation()}
           end) ==
             {annotation(), Graph.new(init: {statement(), EX.ap(), statement()})}
  end

  test "pop/2" do
    assert Graph.pop(graph_with_annotation(), statement()) == {annotation(), graph()}
  end

  test "subject_count/1" do
    assert Graph.subject_count(graph_with_annotations()) == 2
  end

  test "subjects/1" do
    assert Graph.subjects(graph_with_annotations()) == MapSet.new([statement(), RDF.iri(EX.As)])
  end

  test "objects/1" do
    assert Graph.objects(graph_with_annotations()) == MapSet.new([statement(), EX.ao()])
  end

  describe "statements/1" do
    test "without the filter_star flag" do
      assert Graph.statements(graph_with_annotations()) == [
               star_statement(),
               {RDF.iri(EX.As), EX.ap(), statement()}
             ]
    end

    test "with the filter_star flag" do
      assert Graph.statements(graph_with_annotations(), filter_star: true) == []
      assert Graph.statements(graph_with_annotations(), filter_star: true) == []

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

  test "include?/3" do
    assert Graph.include?(graph_with_annotations(), star_statement())
    assert Graph.include?(graph_with_annotations(), {EX.As, EX.ap(), statement()})
  end

  test "describes?/2" do
    assert Graph.describes?(graph_with_annotations(), statement())
  end

  test "values/2" do
    assert graph_with_annotations() |> Graph.values() == %{}

    assert Graph.new(
             init: [
               annotation(),
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

    assert graph_with_annotations() |> Graph.map(mapping) == %{}

    assert Graph.new([
             annotation(),
             {EX.s1(), EX.p(), EX.o1()},
             {EX.s2(), EX.p(), EX.o2()},
             object_annotation()
           ])
           |> Graph.map(mapping) ==
             %{
               RDF.Term.value(EX.s1()) => %{p: [RDF.Term.value(EX.o1())]},
               RDF.Term.value(EX.s2()) => %{p: [RDF.Term.value(EX.o2())]}
             }
  end
end
