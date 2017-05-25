defmodule RDF.DescriptionTest do
  use RDF.Test.Case

  doctest RDF.Description


  describe "new" do
    test "with a subject URI" do
      assert description_of_subject(Description.new(URI.parse("http://example.com/description/subject")),
        URI.parse("http://example.com/description/subject"))
    end

    test "with a raw subject URI string" do
      assert description_of_subject(Description.new("http://example.com/description/subject"),
        URI.parse("http://example.com/description/subject"))
    end

    test "with an unresolved subject URI term atom" do
      assert description_of_subject(Description.new(EX.Bar), uri(EX.Bar))
    end

    test "with a BlankNode subject" do
      assert description_of_subject(Description.new(bnode(:foo)), bnode(:foo))
    end

    test "with a single initial triple" do
      desc = Description.new({EX.Subject, EX.predicate, EX.Object})
      assert description_of_subject(desc, uri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate, uri(EX.Object)})

      desc = Description.new(EX.Subject, EX.predicate, 42)
      assert description_of_subject(desc, uri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate, literal(42)})
    end

    test "with a list of initial triples" do
      desc = Description.new([{EX.Subject, EX.predicate1, EX.Object1},
                              {EX.Subject, EX.predicate2, EX.Object2}])
      assert description_of_subject(desc, uri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate1, uri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2, uri(EX.Object2)})

      desc = Description.new(EX.Subject, EX.predicate, [EX.Object, bnode(:foo), "bar"])
      assert description_of_subject(desc, uri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate, uri(EX.Object)})
      assert description_includes_predication(desc, {EX.predicate, bnode(:foo)})
      assert description_includes_predication(desc, {EX.predicate, literal("bar")})
    end

    test "from another description" do
      desc1 = Description.new({EX.Other, EX.predicate, EX.Object})
      desc2 = Description.new(EX.Subject, desc1)
      assert description_of_subject(desc2, uri(EX.Subject))
      assert description_includes_predication(desc2, {EX.predicate, uri(EX.Object)})
    end

    test "from a map with convertible RDF term" do
      desc = Description.new(EX.Subject, %{EX.Predicate => EX.Object})
      assert description_of_subject(desc, uri(EX.Subject))
      assert description_includes_predication(desc, {uri(EX.Predicate), uri(EX.Object)})
    end

    test "with another description as subject, it performs and add " do
      desc = Description.new({EX.S, EX.p, EX.O})

      assert Description.new(desc, EX.p2, EX.O2) ==
             Description.add(desc, EX.p2, EX.O2)
      assert Description.new(desc, EX.p, [EX.O1, EX.O2]) ==
             Description.add(desc, EX.p, [EX.O1, EX.O2])
    end
  end


  describe "add" do
    test "a predicate-object-pair of proper RDF terms" do
      assert Description.add(description(), EX.predicate, uri(EX.Object))
        |> description_includes_predication({EX.predicate, uri(EX.Object)})
      assert Description.add(description(), {EX.predicate, uri(EX.Object)})
        |> description_includes_predication({EX.predicate, uri(EX.Object)})
    end

    test "a predicate-object-pair of convertible RDF terms" do
      assert Description.add(description(),
              "http://example.com/predicate", uri(EX.Object))
        |> description_includes_predication({EX.predicate, uri(EX.Object)})

      assert Description.add(description(),
              {"http://example.com/predicate", 42})
        |> description_includes_predication({EX.predicate, literal(42)})

      # TODO: Test a url-string as object ...

      assert Description.add(description(),
              {"http://example.com/predicate", bnode(:foo)})
        |> description_includes_predication({EX.predicate, bnode(:foo)})
    end

    test "a proper triple" do
      assert Description.add(description(),
                {uri(EX.Subject), EX.predicate, uri(EX.Object)})
        |> description_includes_predication({EX.predicate, uri(EX.Object)})

      assert Description.add(description(),
                {uri(EX.Subject), EX.predicate, literal(42)})
        |> description_includes_predication({EX.predicate, literal(42)})

      assert Description.add(description(),
                {uri(EX.Subject), EX.predicate, bnode(:foo)})
        |> description_includes_predication({EX.predicate, bnode(:foo)})
    end

    test "add ignores triples not about the subject of the Description struct" do
      assert empty_description(
        Description.add(description(), {EX.Other, EX.predicate, uri(EX.Object)}))
    end

    test "a list of predicate-object-pairs" do
      desc = Description.add(description(),
        [{EX.predicate, EX.Object1}, {EX.predicate, EX.Object2}])
      assert description_includes_predication(desc, {EX.predicate, uri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate, uri(EX.Object2)})
    end

    test "a list of triples" do
      desc = Description.add(description(), [
        {EX.Subject, EX.predicate1, EX.Object1},
        {EX.Subject, EX.predicate2, EX.Object2}
      ])
      assert description_includes_predication(desc, {EX.predicate1, uri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2, uri(EX.Object2)})
    end

    test "a list of mixed triples and predicate-object-pairs" do
      desc = Description.add(description(), [
        {EX.predicate, EX.Object1},
        {EX.Subject, EX.predicate, EX.Object2},
        {EX.Other,   EX.predicate, EX.Object3}
      ])
      assert description_of_subject(desc, uri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate, uri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate, uri(EX.Object2)})
      refute description_includes_predication(desc, {EX.predicate, uri(EX.Object3)})
    end


    test "another description" do
      desc = description([{EX.predicate1, EX.Object1}, {EX.predicate2, EX.Object2}])
        |> Description.add(Description.new({EX.Other, EX.predicate3, EX.Object3}))

      assert description_of_subject(desc, uri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate1, uri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2, uri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate3, uri(EX.Object3)})

      desc = Description.add(desc, Description.new({EX.Other, EX.predicate1, EX.Object4}))
      assert description_includes_predication(desc, {EX.predicate1, uri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2, uri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate3, uri(EX.Object3)})
      assert description_includes_predication(desc, {EX.predicate1, uri(EX.Object4)})
    end

    test "a map of predications with convertible RDF terms" do
      desc = description([{EX.predicate1, EX.Object1}, {EX.predicate2, EX.Object2}])
        |> Description.add(%{EX.predicate3 => EX.Object3})

      assert description_of_subject(desc, uri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate1, uri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2, uri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate3, uri(EX.Object3)})

      desc = Description.add(desc, %{EX.predicate1 => EX.Object1,
                                     EX.predicate2 => [EX.Object2, 42],
                                     EX.predicate3 => [bnode(:foo)]})
      assert Description.count(desc) == 5
      assert description_includes_predication(desc, {EX.predicate1, uri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2, uri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate2, literal(42)})
      assert description_includes_predication(desc, {EX.predicate3, uri(EX.Object3)})
      assert description_includes_predication(desc, {EX.predicate3, bnode(:foo)})
    end

    test "a map of predications with inconvertible RDF terms" do
      assert_raise RDF.InvalidURIError, fn ->
        Description.add(description(), %{"not a URI" => uri(EX.Object)})
      end

      assert_raise RDF.InvalidLiteralError, fn ->
        Description.add(description(), %{EX.prop => self()})
      end
    end

    test "duplicates are ignored" do
      desc = Description.add(description(), {EX.predicate, EX.Object})
      assert Description.add(desc, {EX.predicate, EX.Object}) == desc
      assert Description.add(desc, {EX.Subject, EX.predicate, EX.Object}) == desc

      desc = Description.add(description(), {EX.predicate, 42})
      assert Description.add(desc, {EX.predicate, literal(42)}) == desc
    end

    test "non-convertible Triple elements are causing an error" do
      assert_raise RDF.InvalidURIError, fn ->
        Description.add(description(), {"not a URI", uri(EX.Object)})
      end

      assert_raise RDF.InvalidLiteralError, fn ->
        Description.add(description(), {EX.prop, self()})
      end
    end
  end

  describe "delete" do
    setup do
      {:ok,
        empty_description: Description.new(EX.S),
        description1: Description.new(EX.S, EX.p, EX.O),
        description2: Description.new(EX.S, EX.p, [EX.O1, EX.O2]),
        description3: Description.new(EX.S, [
          {EX.p1, [EX.O1, EX.O2]},
          {EX.p2, EX.O3},
          {EX.p3, [~B<foo>, ~L"bar"]},
        ])
      }
    end

    test "a single statement as a predicate object",
          %{empty_description: empty_description, description1: description1, description2: description2} do
      assert Description.delete(empty_description, EX.p, EX.O) == empty_description
      assert Description.delete(description1, EX.p, EX.O) == empty_description
      assert Description.delete(description2, EX.p, EX.O1) == Description.new(EX.S, EX.p, EX.O2)
    end

    test "a single statement as a predicate-object tuple",
          %{empty_description: empty_description, description1: description1, description2: description2} do
      assert Description.delete(empty_description, {EX.p, EX.O}) == empty_description
      assert Description.delete(description1, {EX.p, EX.O}) == empty_description
      assert Description.delete(description2, {EX.p, EX.O2}) == Description.new(EX.S, EX.p, EX.O1)
    end

    test "a single statement as a subject-predicate-object tuple and the proper description subject",
          %{empty_description: empty_description, description1: description1, description2: description2} do
      assert Description.delete(empty_description, {EX.S, EX.p, EX.O}) == empty_description
      assert Description.delete(description1, {EX.S, EX.p, EX.O}) == empty_description
      assert Description.delete(description2, {EX.S, EX.p, EX.O2}) == Description.new(EX.S, EX.p, EX.O1)
    end

    test "a single statement as a subject-predicate-object tuple and another description subject",
          %{empty_description: empty_description, description1: description1, description2: description2} do
      assert Description.delete(empty_description, {EX.Other, EX.p, EX.O}) == empty_description
      assert Description.delete(description1, {EX.Other, EX.p, EX.O}) == description1
      assert Description.delete(description2, {EX.Other, EX.p, EX.O2}) == description2
    end

    test "multiple statements via predicate-objects tuple",
          %{empty_description: empty_description, description1: description1, description2: description2} do
      assert Description.delete(empty_description, {EX.p, [EX.O1, EX.O2]}) == empty_description
      assert Description.delete(description1, {EX.p, [EX.O, EX.O2]}) == empty_description
      assert Description.delete(description2, {EX.p, [EX.O1, EX.O2]}) == empty_description
    end

    test "multiple statements with a list",
          %{empty_description: empty_description, description3: description3} do
      assert Description.delete(empty_description, [{EX.p, [EX.O1, EX.O2]}]) == empty_description
      assert Description.delete(description3, [
                {EX.p1, EX.O1},
                {EX.p2, [EX.O2, EX.O3]},
                {EX.S, EX.p3, [~B<foo>, ~L"bar"]},
              ]) == Description.new(EX.S, EX.p1, EX.O2)
    end

    test "multiple statements with a map of predications",
          %{empty_description: empty_description, description3: description3} do
      assert Description.delete(empty_description, [{EX.p, [EX.O1, EX.O2]}]) == empty_description
      assert Description.delete(description3, %{
                EX.p1 => EX.O1,
                EX.p2 => [EX.O2, EX.O3],
                EX.p3 => [~B<foo>, ~L"bar"],
              }) == Description.new(EX.S, EX.p1, EX.O2)
    end
  end


  test "pop" do
    assert Description.pop(Description.new(EX.S)) == {nil, Description.new(EX.S)}

    {triple, desc} = Description.new({EX.S, EX.p, EX.O}) |> Description.pop
    assert {uri(EX.S), uri(EX.p), uri(EX.O)} == triple
    assert Enum.count(desc.predications) == 0

    {{subject, predicate, _}, desc} =
      Description.new([{EX.S, EX.p, EX.O1}, {EX.S, EX.p, EX.O2}])
      |> Description.pop
    assert {subject, predicate} == {uri(EX.S), uri(EX.p)}
    assert Enum.count(desc.predications) == 1

    {{subject, _, _}, desc} =
      Description.new([{EX.S, EX.p1, EX.O1}, {EX.S, EX.p2, EX.O2}])
      |> Description.pop
    assert subject == uri(EX.S)
    assert Enum.count(desc.predications) == 1
  end

  describe "Enumerable protocol" do
    test "Enum.count" do
      assert Enum.count(Description.new EX.foo) == 0
      assert Enum.count(Description.new {EX.S, EX.p, EX.O}) == 1
      assert Enum.count(Description.new [{EX.S, EX.p, EX.O1}, {EX.S, EX.p, EX.O2}]) == 2
    end

    test "Enum.member?" do
      refute Enum.member?(Description.new(EX.S), {uri(EX.S), EX.p, uri(EX.O)})
      assert Enum.member?(Description.new({EX.S, EX.p, EX.O}), {EX.S, EX.p, EX.O})

      desc = Description.new([
               {EX.Subject, EX.predicate1, EX.Object1},
               {EX.Subject, EX.predicate2, EX.Object2},
                           {EX.predicate2, EX.Object3}])
      assert Enum.member?(desc, {EX.Subject, EX.predicate1, EX.Object1})
      assert Enum.member?(desc, {EX.Subject, EX.predicate2, EX.Object2})
      assert Enum.member?(desc, {EX.Subject, EX.predicate2, EX.Object3})
      refute Enum.member?(desc, {EX.Subject, EX.predicate1, EX.Object2})
    end

    test "Enum.reduce" do
      desc = Description.new([
               {EX.Subject, EX.predicate1, EX.Object1},
               {EX.Subject, EX.predicate2, EX.Object2},
                           {EX.predicate2, EX.Object3}])
      assert desc == Enum.reduce(desc, description(),
        fn(triple, acc) -> acc |> Description.add(triple) end)
    end
  end

  describe "Access behaviour" do
    test "access with the [] operator" do
      assert Description.new(EX.Subject)[EX.predicate] == nil
      assert Description.new(EX.Subject, EX.predicate, EX.Object)[EX.predicate] == [uri(EX.Object)]
      assert Description.new(EX.Subject, EX.Predicate, EX.Object)[EX.Predicate] == [uri(EX.Object)]
      assert Description.new(EX.Subject, EX.predicate, EX.Object)["http://example.com/predicate"] == [uri(EX.Object)]
      assert Description.new([{EX.Subject, EX.predicate1, EX.Object1},
                              {EX.Subject, EX.predicate1, EX.Object2},
                              {EX.Subject, EX.predicate2, EX.Object3}])[EX.predicate1] ==
              [uri(EX.Object1), uri(EX.Object2)]
    end

  end

  describe "RDF.Data protocol implementation" do
    setup do
      {:ok,
        description: Description.new(EX.S, [
          {EX.p1, [EX.O1, EX.O2]},
          {EX.p2, EX.O3},
          {EX.p3, [~B<foo>, ~L"bar"]},
        ])
      }
    end

    test "add", %{description: description} do
      assert RDF.Data.add(description, {EX.S, EX.p1, EX.O4}) ==
              Description.add(description, {EX.S, EX.p1, EX.O4})

      assert RDF.Data.add(description, {EX.Other, EX.p2, EX.O4}) == description
    end

    test "put", %{description: description} do
      assert RDF.Data.put(description, {EX.S, EX.p1, EX.O4}) ==
              Description.put(description, {EX.S, EX.p1, EX.O4})

      assert RDF.Data.put(description, {EX.Other, EX.p2, EX.O4}) == description
    end

    test "delete", %{description: description} do
      assert RDF.Data.delete(description, {EX.S, EX.p1, EX.O2}) ==
              Description.delete(description, {EX.S, EX.p1, EX.O2})

      assert RDF.Data.delete(description, {EX.Other, EX.p1, EX.O2}) == description
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

end
