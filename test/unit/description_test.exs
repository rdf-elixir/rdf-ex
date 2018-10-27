defmodule RDF.DescriptionTest do
  use RDF.Test.Case

  doctest RDF.Description


  describe "new" do
    test "with a subject IRI" do
      assert description_of_subject(Description.new(~I<http://example.com/description/subject>),
        ~I<http://example.com/description/subject>)
    end

    test "with a raw subject IRI string" do
      assert description_of_subject(Description.new("http://example.com/description/subject"),
        ~I<http://example.com/description/subject>)
    end

    test "with an unresolved subject IRI term atom" do
      assert description_of_subject(Description.new(EX.Bar), iri(EX.Bar))
    end

    test "with a BlankNode subject" do
      assert description_of_subject(Description.new(bnode(:foo)), bnode(:foo))
    end

    test "with a single initial triple" do
      desc = Description.new({EX.Subject, EX.predicate, EX.Object})
      assert description_of_subject(desc, iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate, iri(EX.Object)})

      desc = Description.new(EX.Subject, EX.predicate, 42)
      assert description_of_subject(desc, iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate, literal(42)})
    end

    test "with a list of initial triples" do
      desc = Description.new([{EX.Subject, EX.predicate1, EX.Object1},
                              {EX.Subject, EX.predicate2, EX.Object2}])
      assert description_of_subject(desc, iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate1, iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2, iri(EX.Object2)})

      desc = Description.new(EX.Subject, EX.predicate, [EX.Object, bnode(:foo), "bar"])
      assert description_of_subject(desc, iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate, iri(EX.Object)})
      assert description_includes_predication(desc, {EX.predicate, bnode(:foo)})
      assert description_includes_predication(desc, {EX.predicate, literal("bar")})
    end

    test "from another description" do
      desc1 = Description.new({EX.Other, EX.predicate, EX.Object})
      desc2 = Description.new(EX.Subject, desc1)
      assert description_of_subject(desc2, iri(EX.Subject))
      assert description_includes_predication(desc2, {EX.predicate, iri(EX.Object)})
    end

    test "from a map with coercible RDF term" do
      desc = Description.new(EX.Subject, %{EX.Predicate => EX.Object})
      assert description_of_subject(desc, iri(EX.Subject))
      assert description_includes_predication(desc, {iri(EX.Predicate), iri(EX.Object)})
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
      assert Description.add(description(), EX.predicate, iri(EX.Object))
        |> description_includes_predication({EX.predicate, iri(EX.Object)})
      assert Description.add(description(), {EX.predicate, iri(EX.Object)})
        |> description_includes_predication({EX.predicate, iri(EX.Object)})
    end

    test "a predicate-object-pair of coercible RDF terms" do
      assert Description.add(description(),
              "http://example.com/predicate", iri(EX.Object))
        |> description_includes_predication({EX.predicate, iri(EX.Object)})

      assert Description.add(description(),
              {"http://example.com/predicate", 42})
        |> description_includes_predication({EX.predicate, literal(42)})

      assert Description.add(description(),
              {"http://example.com/predicate", true})
        |> description_includes_predication({EX.predicate, literal(true)})

      assert Description.add(description(),
              {"http://example.com/predicate", bnode(:foo)})
        |> description_includes_predication({EX.predicate, bnode(:foo)})
    end

    test "a proper triple" do
      assert Description.add(description(),
                {iri(EX.Subject), EX.predicate, iri(EX.Object)})
        |> description_includes_predication({EX.predicate, iri(EX.Object)})

      assert Description.add(description(),
                {iri(EX.Subject), EX.predicate, literal(42)})
        |> description_includes_predication({EX.predicate, literal(42)})

      assert Description.add(description(),
                {iri(EX.Subject), EX.predicate, bnode(:foo)})
        |> description_includes_predication({EX.predicate, bnode(:foo)})
    end

    test "add ignores triples not about the subject of the Description struct" do
      assert empty_description(
        Description.add(description(), {EX.Other, EX.predicate, iri(EX.Object)}))
    end

    test "a list of predicate-object-pairs" do
      desc = Description.add(description(),
        [{EX.predicate, EX.Object1}, {EX.predicate, EX.Object2}])
      assert description_includes_predication(desc, {EX.predicate, iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate, iri(EX.Object2)})
    end

    test "a list of triples" do
      desc = Description.add(description(), [
        {EX.Subject, EX.predicate1, EX.Object1},
        {EX.Subject, EX.predicate2, EX.Object2}
      ])
      assert description_includes_predication(desc, {EX.predicate1, iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2, iri(EX.Object2)})
    end

    test "a list of mixed triples and predicate-object-pairs" do
      desc = Description.add(description(), [
        {EX.predicate, EX.Object1},
        {EX.Subject, EX.predicate, EX.Object2},
        {EX.Other,   EX.predicate, EX.Object3}
      ])
      assert description_of_subject(desc, iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate, iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate, iri(EX.Object2)})
      refute description_includes_predication(desc, {EX.predicate, iri(EX.Object3)})
    end


    test "another description" do
      desc = description([{EX.predicate1, EX.Object1}, {EX.predicate2, EX.Object2}])
        |> Description.add(Description.new({EX.Other, EX.predicate3, EX.Object3}))

      assert description_of_subject(desc, iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate1, iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2, iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate3, iri(EX.Object3)})

      desc = Description.add(desc, Description.new({EX.Other, EX.predicate1, EX.Object4}))
      assert description_includes_predication(desc, {EX.predicate1, iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2, iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate3, iri(EX.Object3)})
      assert description_includes_predication(desc, {EX.predicate1, iri(EX.Object4)})
    end

    test "a map of predications with coercible RDF terms" do
      desc = description([{EX.predicate1, EX.Object1}, {EX.predicate2, EX.Object2}])
        |> Description.add(%{EX.predicate3 => EX.Object3})

      assert description_of_subject(desc, iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate1, iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2, iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate3, iri(EX.Object3)})

      desc = Description.add(desc, %{EX.predicate1 => EX.Object1,
                                     EX.predicate2 => [EX.Object2, 42],
                                     EX.predicate3 => [bnode(:foo)]})
      assert Description.count(desc) == 5
      assert description_includes_predication(desc, {EX.predicate1, iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2, iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate2, literal(42)})
      assert description_includes_predication(desc, {EX.predicate3, iri(EX.Object3)})
      assert description_includes_predication(desc, {EX.predicate3, bnode(:foo)})
    end

    test "a map of predications with non-coercible RDF terms" do
      assert_raise RDF.IRI.InvalidError, fn ->
        Description.add(description(), %{"not a IRI" => iri(EX.Object)})
      end

      assert_raise RDF.Literal.InvalidError, fn ->
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

    test "non-coercible Triple elements are causing an error" do
      assert_raise RDF.IRI.InvalidError, fn ->
        Description.add(description(), {"not a IRI", iri(EX.Object)})
      end

      assert_raise RDF.Literal.InvalidError, fn ->
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
      assert Description.delete(empty_description, %{EX.p => EX.O1}) == empty_description
      assert Description.delete(description3, %{
                EX.p1 => EX.O1,
                EX.p2 => [EX.O2, EX.O3],
                EX.p3 => [~B<foo>, ~L"bar"],
              }) == Description.new(EX.S, EX.p1, EX.O2)
    end

    test "multiple statements with another description",
          %{empty_description: empty_description, description1: description1, description3: description3} do
      assert Description.delete(empty_description, description1) == empty_description
      assert Description.delete(description3, Description.new(EX.S, %{
                EX.p1 => EX.O1,
                EX.p2 => [EX.O2, EX.O3],
                EX.p3 => [~B<foo>, ~L"bar"],
              })) == Description.new(EX.S, EX.p1, EX.O2)
    end
  end


  describe "delete_predicates" do
    setup do
      {:ok,
        empty_description: Description.new(EX.S),
        description1: Description.new(EX.S, EX.p, [EX.O1, EX.O2]),
        description2: Description.new(EX.S, [
          {EX.P1, [EX.O1, EX.O2]},
          {EX.p2, [~B<foo>, ~L"bar"]},
        ])
      }
    end

    test "a single property",
          %{empty_description: empty_description, description1: description1, description2: description2}  do
      assert Description.delete_predicates(description1, EX.p) == empty_description
      assert Description.delete_predicates(description2, EX.P1) ==
              Description.new(EX.S, EX.p2, [~B<foo>, ~L"bar"])
    end

    test "a list of properties",
          %{empty_description: empty_description, description1: description1, description2: description2}  do
      assert Description.delete_predicates(description1, [EX.p]) == empty_description
      assert Description.delete_predicates(description2, [EX.P1, EX.p2, EX.p3]) == empty_description
    end
  end


  test "pop" do
    assert Description.pop(Description.new(EX.S)) == {nil, Description.new(EX.S)}

    {triple, desc} = Description.new({EX.S, EX.p, EX.O}) |> Description.pop
    assert {iri(EX.S), iri(EX.p), iri(EX.O)} == triple
    assert Enum.count(desc.predications) == 0

    {{subject, predicate, _}, desc} =
      Description.new([{EX.S, EX.p, EX.O1}, {EX.S, EX.p, EX.O2}])
      |> Description.pop
    assert {subject, predicate} == {iri(EX.S), iri(EX.p)}
    assert Enum.count(desc.predications) == 1

    {{subject, _, _}, desc} =
      Description.new([{EX.S, EX.p1, EX.O1}, {EX.S, EX.p2, EX.O2}])
      |> Description.pop
    assert subject == iri(EX.S)
    assert Enum.count(desc.predications) == 1
  end

  test "values/1" do
      assert Description.new(EX.s) |> Description.values() == %{}
      assert Description.new({EX.s, EX.p, ~L"Foo"}) |> Description.values() ==
               %{RDF.Term.value(EX.p) => ["Foo"]}
  end

  describe "Enumerable protocol" do
    test "Enum.count" do
      assert Enum.count(Description.new EX.foo) == 0
      assert Enum.count(Description.new {EX.S, EX.p, EX.O}) == 1
      assert Enum.count(Description.new [{EX.S, EX.p, EX.O1}, {EX.S, EX.p, EX.O2}]) == 2
    end

    test "Enum.member?" do
      refute Enum.member?(Description.new(EX.S), {iri(EX.S), EX.p, iri(EX.O)})
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

  describe "Collectable protocol" do
    test "with a map" do
      map = %{
          EX.predicate1 => EX.Object1,
          EX.predicate2 => EX.Object2
        }
      assert Enum.into(map, Description.new(EX.Subject)) == Description.new(EX.Subject, map)
    end

    test "with a list of triples" do
      triples = [
          {EX.Subject, EX.predicate1, EX.Object1},
          {EX.Subject, EX.predicate2, EX.Object2}
        ]
      assert Enum.into(triples, Description.new(EX.Subject)) == Description.new(triples)
    end

    test "with a list of predicate-object pairs" do
      pairs = [
          {EX.predicate1, EX.Object1},
          {EX.predicate2, EX.Object2}
        ]
      assert Enum.into(pairs, Description.new(EX.Subject)) == Description.new(EX.Subject, pairs)
    end

    test "with a list of lists" do
      lists = [
          [EX.Subject, EX.predicate1, EX.Object1],
          [EX.Subject, EX.predicate2, EX.Object2]
        ]
      assert Enum.into(lists, Description.new(EX.Subject)) ==
              Description.new(Enum.map(lists, &List.to_tuple/1))
    end
  end

  describe "Access behaviour" do
    test "access with the [] operator" do
      assert Description.new(EX.Subject)[EX.predicate] == nil
      assert Description.new(EX.Subject, EX.predicate, EX.Object)[EX.predicate] == [iri(EX.Object)]
      assert Description.new(EX.Subject, EX.Predicate, EX.Object)[EX.Predicate] == [iri(EX.Object)]
      assert Description.new(EX.Subject, EX.predicate, EX.Object)["http://example.com/predicate"] == [iri(EX.Object)]
      assert Description.new([{EX.Subject, EX.predicate1, EX.Object1},
                              {EX.Subject, EX.predicate1, EX.Object2},
                              {EX.Subject, EX.predicate2, EX.Object3}])[EX.predicate1] ==
              [iri(EX.Object1), iri(EX.Object2)]
    end
  end

end
