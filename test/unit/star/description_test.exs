defmodule RDF.Star.Description.Test do
  use RDF.Test.Case

  describe "new/1" do
    test "with a valid triple as subject" do
      assert description_of_subject(
               Description.new(statement()),
               statement()
             )

      assert Description.new(statement(), init: {EX.ap(), EX.ao()})
             |> description_includes_predication({EX.ap(), EX.ao()})
    end

    test "with a coercible triple as subject" do
      assert description_of_subject(
               Description.new(coercible_statement()),
               statement()
             )

      assert Description.new(statement(), init: {EX.ap(), EX.ao()})
             |> description_includes_predication({EX.ap(), EX.ao()})
    end
  end

  test "subject/1" do
    assert Description.subject(empty_annotation()) == statement()
  end

  test "change_subject/2" do
    changed = Description.change_subject(description(), coercible_statement())
    assert changed.subject == statement()
    assert Description.change_subject(changed, description().subject) == description()
  end

  describe "add/3" do
    test "with a proper triple as a subject" do
      assert empty_annotation()
             |> Description.add({statement(), EX.ap(), EX.ao()})
             |> description_includes_predication({EX.ap(), EX.ao()})
    end

    test "with a proper triple as a object" do
      assert description()
             |> Description.add({EX.Subject, EX.ap(), statement()})
             |> description_includes_predication({EX.ap(), statement()})
    end

    test "with a proper triple as a subject and object" do
      assert empty_annotation()
             |> Description.add({statement(), EX.ap(), statement()})
             |> description_includes_predication({EX.ap(), statement()})
    end

    test "with a list of proper objects" do
      description =
        description()
        |> Description.add({EX.Subject, EX.ap(), [statement(), {EX.s(), EX.p(), EX.o()}]})

      assert description_includes_predication(description, {EX.ap(), statement()})
      assert description_includes_predication(description, {EX.ap(), {EX.s(), EX.p(), EX.o()}})
    end

    test "with a list of predicate-object tuples" do
      assert empty_annotation()
             |> Description.add([{EX.ap(), statement()}])
             |> description_includes_predication({EX.ap(), statement()})
    end

    test "with a description map" do
      assert empty_annotation()
             |> Description.add(%{EX.ap() => statement()})
             |> description_includes_predication({EX.ap(), statement()})
    end

    test "with coercible triples" do
      assert empty_annotation()
             |> Description.add({coercible_statement(), EX.ap(), coercible_statement()})
             |> description_includes_predication({EX.ap(), statement()})
    end
  end

  test "put/3" do
    assert annotation()
           |> Description.put({statement(), EX.ap(), EX.ao2()})
           |> description_includes_predication({EX.ap(), EX.ao2()})

    assert annotation()
           |> Description.put({statement(), EX.ap(), statement()})
           |> description_includes_predication({EX.ap(), statement()})
  end

  test "delete/3" do
    assert Description.delete(annotation(), {statement(), EX.ap(), EX.ao()}) ==
             empty_annotation()

    assert Description.delete(object_annotation(), {EX.As, EX.ap(), statement()}) ==
             Description.new(EX.As)

    assert Description.delete(object_annotation(), {EX.ap(), statement()}) ==
             Description.new(EX.As)
  end

  test "delete_predicates/2" do
    assert Description.delete_predicates(annotation(), EX.ap()) ==
             empty_annotation()

    assert Description.delete_predicates(object_annotation(), EX.ap()) ==
             Description.new(EX.As)
  end

  test "fetch/2" do
    assert Description.fetch(annotation(), EX.ap()) == {:ok, [EX.ao()]}
    assert Description.fetch(object_annotation(), EX.ap()) == {:ok, [statement()]}
  end

  test "get/2" do
    assert Description.get(annotation(), EX.ap()) == [EX.ao()]
    assert Description.get(object_annotation(), EX.ap()) == [statement()]
  end

  test "first/2" do
    assert Description.first(annotation(), EX.ap()) == EX.ao()
    assert Description.first(object_annotation(), EX.ap()) == statement()
  end

  test "pop/2" do
    assert Description.pop(annotation(), EX.ap()) == {[EX.ao()], empty_annotation()}

    assert Description.pop(object_annotation(), EX.ap()) ==
             {[statement()], Description.new(EX.As)}
  end

  test "update/4" do
    assert (description =
              Description.update(empty_annotation(), EX.ap(), statement(), fn _ ->
                raise "unexpected"
              end)) ==
             empty_annotation()
             |> Description.add(%{EX.ap() => statement()})

    assert Description.update(description, EX.ap(), statement(), fn
             [{s, p, _} = statement] ->
               assert statement == statement()
               [statement, {s, p, EX.O}]
           end) ==
             empty_annotation()
             |> Description.add(%{EX.ap() => statement()})
             |> Description.add(%{EX.ap() => {EX.S, EX.P, EX.O}})
  end

  test "objects/1" do
    assert Description.new(statement(), init: {EX.ap(), statement()})
           |> Description.objects() == MapSet.new([statement()])
  end

  test "resources/1" do
    assert Description.new(statement(), init: {EX.ap(), statement()})
           |> Description.resources() == MapSet.new([statement(), EX.ap()])
  end

  describe "statements/1" do
    test "without the filter_star flag" do
      assert Description.new(statement(), init: {EX.ap(), statement()})
             |> Description.statements() == [{statement(), EX.ap(), statement()}]
    end

    test "with the filter_star flag" do
      assert Description.new(statement(),
               init: [
                 {EX.ap(), EX.ao()},
                 {EX.ap(), statement()}
               ]
             )
             |> Description.statements(filter_star: true) == []

      assert Description.new(EX.s(),
               init: [
                 {EX.p(), EX.o()},
                 {EX.ap(), statement()}
               ]
             )
             |> Description.statements(filter_star: true) == [{EX.s(), EX.p(), EX.o()}]
    end
  end

  test "statement_count/1" do
    assert Description.new(statement(), init: {EX.ap(), statement()})
           |> Description.statement_count() == 1
  end

  test "include?/2" do
    assert Description.new(statement(), init: {EX.ap(), statement()})
           |> Description.include?({statement(), EX.ap(), statement()})
  end

  test "describes?/2" do
    assert Description.describes?(annotation(), statement())
    assert Description.describes?(annotation(), coercible_statement())
  end

  test "values/2" do
    assert Description.new(statement(), init: {EX.ap(), statement()})
           |> Description.values() == %{}

    assert Description.new(EX.s(),
             init: [
               {EX.p(), ~L"Foo"},
               {EX.ap(), statement()}
             ]
           )
           |> Description.values() ==
             %{RDF.Term.value(EX.p()) => ["Foo"]}
  end

  test "map/2" do
    mapping = fn
      {:predicate, predicate} ->
        predicate |> to_string() |> String.split("/") |> List.last() |> String.to_atom()

      {_, term} ->
        RDF.Term.value(term)
    end

    assert Description.new(statement(), init: {EX.ap(), statement()})
           |> Description.map(mapping) == %{}

    assert Description.new(EX.s(),
             init: [
               {EX.p(), ~L"Foo"},
               {EX.ap(), statement()}
             ]
           )
           |> Description.map(mapping) ==
             %{p: ["Foo"]}
  end
end
