defmodule RDF.DescriptionTest do
  use RDF.Test.Case

  doctest RDF.Description

  describe "new" do
    test "with a subject IRI" do
      assert description_of_subject(
               Description.new(~I<http://example.com/description/subject>),
               ~I<http://example.com/description/subject>
             )
    end

    test "with a raw subject IRI string" do
      assert description_of_subject(
               Description.new("http://example.com/description/subject"),
               ~I<http://example.com/description/subject>
             )
    end

    test "with an unresolved subject IRI term atom" do
      assert description_of_subject(Description.new(EX.Bar), iri(EX.Bar))
    end

    test "with a BlankNode subject" do
      assert description_of_subject(Description.new(bnode(:foo)), bnode(:foo))
    end

    test "with another description" do
      existing_description = description({EX.Subject, EX.predicate(), EX.Object})
      new_description = Description.new(existing_description)
      assert description_of_subject(new_description, iri(EX.Subject))
      refute description_includes_predication(new_description, {EX.predicate(), iri(EX.Object)})
    end

    test "with init data" do
      desc = Description.new(EX.Subject, init: {EX.Subject, EX.predicate(), EX.Object})
      assert description_of_subject(desc, iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate(), iri(EX.Object)})

      desc =
        Description.new(
          EX.Subject,
          init: [
            {EX.Subject, EX.predicate1(), EX.Object1},
            {EX.Subject, EX.predicate2(), EX.Object2}
          ]
        )

      assert description_of_subject(desc, iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate1(), iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), iri(EX.Object2)})

      other_desc = Description.new(EX.Subject2, init: {EX.Subject2, EX.predicate(), EX.Object})
      desc = Description.new(EX.Subject, init: other_desc)
      assert description_of_subject(desc, iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate(), iri(EX.Object)})
    end

    test "with an initializer function" do
      desc = Description.new(EX.Subject, init: fn -> {EX.Subject, EX.predicate(), EX.Object} end)
      assert description_of_subject(desc, iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate(), iri(EX.Object)})
    end
  end

  test "subject/1" do
    assert Description.subject(description()) == description().subject
  end

  test "change_subject/2" do
    assert Description.change_subject(description(), EX.NewSubject).subject ==
             iri(EX.NewSubject)
  end

  describe "add/3" do
    test "with a triple" do
      assert Description.add(description(), {iri(EX.Subject), EX.predicate(), iri(EX.Object)})
             |> description_includes_predication({EX.predicate(), iri(EX.Object)})

      assert Description.add(description(), {iri(EX.Subject), EX.predicate(), bnode(:foo)})
             |> description_includes_predication({EX.predicate(), bnode(:foo)})

      assert Description.add(description(), {iri(EX.Subject), EX.predicate(), literal(42)})
             |> description_includes_predication({EX.predicate(), literal(42)})
    end

    test "with a predicate-object tuple" do
      assert Description.add(description(), {EX.predicate(), iri(EX.Object)})
             |> description_includes_predication({EX.predicate(), iri(EX.Object)})
    end

    test "with a predicate-object tuple and a list of objects" do
      desc = Description.add(description(), {EX.p(), [iri(EX.O1), iri(EX.O2)]})
      assert description_includes_predication(desc, {EX.p(), iri(EX.O1)})
      assert description_includes_predication(desc, {EX.p(), iri(EX.O2)})
    end

    test "with a list of predicate-object tuples" do
      desc =
        Description.add(description(), [
          {EX.predicate(), EX.Object1},
          {EX.predicate(), EX.Object2}
        ])

      assert description_includes_predication(desc, {EX.predicate(), iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate(), iri(EX.Object2)})

      desc =
        Description.add(description(), [
          {EX.p1(), EX.O1},
          {EX.p2(), [EX.O2, ~L"foo", "bar", 42]}
        ])

      assert description_includes_predication(desc, {EX.p1(), iri(EX.O1)})
      assert description_includes_predication(desc, {EX.p2(), iri(EX.O2)})
      assert description_includes_predication(desc, {EX.p2(), ~L"foo"})
      assert description_includes_predication(desc, {EX.p2(), ~L"bar"})
      assert description_includes_predication(desc, {EX.p2(), RDF.literal(42)})
    end

    test "with a list of triples" do
      desc =
        Description.add(description(), [
          {EX.Subject, EX.predicate1(), EX.Object1},
          {EX.Subject, EX.predicate2(), EX.Object2}
        ])

      assert description_includes_predication(desc, {EX.predicate1(), iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), iri(EX.Object2)})

      desc =
        Description.add(description(), [
          {EX.Subject, EX.predicate1(), EX.Object1},
          {EX.Subject, EX.predicate2(), [EX.Object2, EX.Object3]}
        ])

      assert description_includes_predication(desc, {EX.predicate1(), iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate2(), iri(EX.Object3)})
    end

    test "a list of mixed triples and predicate-object-pairs" do
      desc =
        Description.add(description(), [
          {EX.predicate(), EX.Object1},
          {EX.Subject, EX.predicate(), EX.Object2},
          {EX.Other, EX.predicate(), EX.Object3}
        ])

      assert description_of_subject(desc, iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate(), iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate(), iri(EX.Object2)})
      refute description_includes_predication(desc, {EX.predicate(), iri(EX.Object3)})
    end

    test "with a description map with coercible RDF terms" do
      desc =
        description([{EX.predicate1(), EX.Object1}, {EX.predicate2(), EX.Object2}])
        |> Description.add(%{EX.predicate3() => EX.Object3})

      assert description_of_subject(desc, iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate1(), iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate3(), iri(EX.Object3)})

      desc =
        Description.add(desc, %{
          EX.predicate1() => EX.Object1,
          EX.predicate2() => [EX.Object2, 42],
          EX.predicate3() => [bnode(:foo)]
        })

      assert Description.count(desc) == 5
      assert description_includes_predication(desc, {EX.predicate1(), iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate2(), literal(42)})
      assert description_includes_predication(desc, {EX.predicate3(), iri(EX.Object3)})
      assert description_includes_predication(desc, {EX.predicate3(), bnode(:foo)})
    end

    test "a map of predications with non-coercible RDF terms" do
      assert_raise RDF.IRI.InvalidError, fn ->
        Description.add(description(), %{"not a IRI" => iri(EX.Object)})
      end

      assert_raise RDF.Literal.InvalidError, fn ->
        Description.add(description(), %{EX.prop() => self()})
      end
    end

    test "with an empty map" do
      assert Description.add(description(), %{}) == description()
    end

    test "with empty object lists" do
      assert Description.add(description(), {EX.p(), []}) == description()
      assert Description.add(description(), %{EX.p() => []}) == description()
    end

    test "with another description" do
      desc =
        description([{EX.predicate1(), EX.Object1}, {EX.predicate2(), EX.Object2}])
        |> Description.add(
          Description.new(EX.Other, init: {EX.Other, EX.predicate3(), EX.Object3})
        )

      assert description_of_subject(desc, iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate1(), iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate3(), iri(EX.Object3)})

      desc =
        Description.add(
          desc,
          Description.new(EX.Other, init: {EX.Other, EX.predicate1(), EX.Object4})
        )

      assert description_includes_predication(desc, {EX.predicate1(), iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate3(), iri(EX.Object3)})
      assert description_includes_predication(desc, {EX.predicate1(), iri(EX.Object4)})
    end

    test "triples with another subject are ignored" do
      assert empty_description(
               Description.add(description(), {EX.Other, EX.predicate(), iri(EX.Object)})
             )
    end

    test "duplicates are ignored" do
      desc = Description.add(description(), {EX.predicate(), EX.Object})
      assert Description.add(desc, {EX.predicate(), EX.Object}) == desc
      assert Description.add(desc, {EX.Subject, EX.predicate(), EX.Object}) == desc

      desc = Description.add(description(), {EX.predicate(), 42})
      assert Description.add(desc, {EX.predicate(), literal(42)}) == desc
    end

    test "coercion" do
      assert Description.add(description(), {EX.Subject, EX.P, EX.O})
             |> description_includes_predication({iri(EX.P), iri(EX.O)})

      assert Description.add(description(), {"http://example.com/predicate", EX.Object})
             |> description_includes_predication({EX.predicate(), iri(EX.Object)})

      desc = Description.add(description(), {"http://example.com/predicate", [42, true]})
      assert description_includes_predication(desc, {EX.predicate(), literal(42)})
      assert description_includes_predication(desc, {EX.predicate(), literal(true)})
    end

    test "non-coercible Triple elements are causing an error" do
      assert_raise RDF.IRI.InvalidError, fn ->
        Description.add(description(), {"not a IRI", iri(EX.Object)})
      end

      assert_raise RDF.Literal.InvalidError, fn ->
        Description.add(description(), {EX.prop(), self()})
      end
    end
  end

  describe "put/3" do
    test "with a triple" do
      assert Description.put(description(), {iri(EX.Subject), EX.predicate(), iri(EX.Object)})
             |> description_includes_predication({EX.predicate(), iri(EX.Object)})
    end

    test "with a predicate-object tuple" do
      desc = Description.put(description(), {EX.p(), [iri(EX.O1), iri(EX.O2)]})
      assert description_includes_predication(desc, {EX.p(), iri(EX.O1)})
      assert description_includes_predication(desc, {EX.p(), iri(EX.O2)})
    end

    test "with a list of predicate-object tuples" do
      desc =
        Description.put(description(), [
          {EX.p1(), EX.O1},
          {EX.p2(), [EX.O2]},
          {EX.p2(), [~L"foo", "bar", 42]}
        ])

      assert description_includes_predication(desc, {EX.p1(), iri(EX.O1)})
      assert description_includes_predication(desc, {EX.p2(), iri(EX.O2)})
      assert description_includes_predication(desc, {EX.p2(), ~L"foo"})
      assert description_includes_predication(desc, {EX.p2(), ~L"bar"})
      assert description_includes_predication(desc, {EX.p2(), RDF.literal(42)})
    end

    test "with a list of triples" do
      desc =
        Description.put(description(), [
          {EX.Subject, EX.predicate1(), EX.Object1},
          {EX.Subject, EX.predicate2(), [EX.Object2, EX.Object3]},
          {EX.Subject, EX.predicate2(), [EX.Object4]}
        ])

      assert description_includes_predication(desc, {EX.predicate1(), iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate2(), iri(EX.Object3)})
      assert description_includes_predication(desc, {EX.predicate2(), iri(EX.Object4)})
    end

    test "with a description map with coercible RDF terms" do
      desc =
        description([{EX.predicate1(), EX.Object1}, {EX.predicate2(), EX.Object2}])
        |> Description.put(%{
          EX.predicate2() => [EX.Object3, 42],
          EX.predicate3() => bnode(:foo)
        })

      assert Description.count(desc) == 4
      assert description_includes_predication(desc, {EX.predicate1(), iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), iri(EX.Object3)})
      assert description_includes_predication(desc, {EX.predicate2(), literal(42)})
      assert description_includes_predication(desc, {EX.predicate3(), bnode(:foo)})
      refute description_includes_predication(desc, {EX.predicate2(), iri(EX.Object2)})
    end

    test "with an empty map" do
      desc = description([{EX.predicate(), EX.Object}])
      assert Description.put(desc, %{}) == desc
    end

    test "with a description on the same subject" do
      desc =
        description([{EX.predicate1(), EX.Object1}, {EX.predicate2(), EX.Object2}])
        |> Description.put(
          description([
            {EX.predicate1(), EX.Object4},
            {EX.predicate3(), EX.Object3}
          ])
        )

      assert Description.count(desc) == 3

      assert description_includes_predication(desc, {EX.predicate1(), iri(EX.Object4)})
      assert description_includes_predication(desc, {EX.predicate2(), iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate3(), iri(EX.Object3)})
    end

    test "with a description on another subject" do
      desc = description([{EX.predicate1(), EX.Object1}, {EX.predicate2(), EX.Object2}])

      assert Description.put(
               desc,
               Description.new(EX.Other, init: {EX.Other, EX.predicate(), iri(EX.Object)})
             ) == desc
    end

    test "triples with another subject are ignored" do
      assert empty_description(
               Description.put(description(), {EX.Other, EX.predicate(), iri(EX.Object)})
             )
    end
  end

  describe "delete" do
    setup do
      {:ok,
       empty_description: Description.new(EX.S),
       description1: Description.new(EX.S, init: {EX.S, EX.p(), EX.O}),
       description2: Description.new(EX.S, init: {EX.S, EX.p(), [EX.O1, EX.O2]}),
       description3:
         Description.new(EX.S,
           init: [
             {EX.p1(), [EX.O1, EX.O2]},
             {EX.p2(), EX.O3},
             {EX.p3(), [~B<foo>, ~L"bar"]}
           ]
         )}
    end

    test "a single statement as a predicate-object tuple",
         %{
           empty_description: empty_description,
           description1: description1,
           description2: description2
         } do
      assert Description.delete(empty_description, {EX.p(), EX.O}) == empty_description
      assert Description.delete(description1, {EX.p(), EX.O}) == empty_description

      assert Description.delete(description2, {EX.p(), EX.O2}) ==
               Description.new(EX.S, init: {EX.S, EX.p(), EX.O1})
    end

    test "a single statement as a subject-predicate-object tuple and the proper description subject",
         %{
           empty_description: empty_description,
           description1: description1,
           description2: description2
         } do
      assert Description.delete(empty_description, {EX.S, EX.p(), EX.O}) == empty_description
      assert Description.delete(description1, {EX.S, EX.p(), EX.O}) == empty_description

      assert Description.delete(description2, {EX.S, EX.p(), EX.O2}) ==
               Description.new(EX.S, init: {EX.S, EX.p(), EX.O1})
    end

    test "a single statement as a subject-predicate-object tuple and another description subject",
         %{
           empty_description: empty_description,
           description1: description1,
           description2: description2
         } do
      assert Description.delete(empty_description, {EX.Other, EX.p(), EX.O}) == empty_description
      assert Description.delete(description1, {EX.Other, EX.p(), EX.O}) == description1
      assert Description.delete(description2, {EX.Other, EX.p(), EX.O2}) == description2
    end

    test "multiple statements via predicate-objects tuple",
         %{
           empty_description: empty_description,
           description1: description1,
           description2: description2
         } do
      assert Description.delete(empty_description, {EX.p(), [EX.O1, EX.O2]}) == empty_description
      assert Description.delete(description1, {EX.p(), [EX.O, EX.O2]}) == empty_description
      assert Description.delete(description2, {EX.p(), [EX.O1, EX.O2]}) == empty_description
    end

    test "multiple statements with a list",
         %{empty_description: empty_description, description3: description3} do
      assert Description.delete(empty_description, [{EX.p(), [EX.O1, EX.O2]}]) ==
               empty_description

      assert Description.delete(description3, [
               {EX.p1(), EX.O1},
               {EX.p2(), [EX.O2, EX.O3]},
               {EX.S, EX.p3(), [~B<foo>, ~L"bar"]}
             ]) == Description.new(EX.S, init: {EX.S, EX.p1(), EX.O2})
    end

    test "multiple statements with a map of predications",
         %{empty_description: empty_description, description3: description3} do
      assert Description.delete(empty_description, %{EX.p() => EX.O1}) == empty_description

      assert Description.delete(description3, %{
               EX.p1() => EX.O1,
               EX.p2() => [EX.O2, EX.O3],
               EX.p3() => [~B<foo>, ~L"bar"]
             }) == Description.new(EX.S, init: {EX.S, EX.p1(), EX.O2})
    end

    test "multiple statements with another description",
         %{
           empty_description: empty_description,
           description1: description1,
           description3: description3
         } do
      assert Description.delete(empty_description, description1) == empty_description

      assert Description.delete(
               description3,
               Description.new(EX.S,
                 init: %{
                   EX.p1() => EX.O1,
                   EX.p2() => [EX.O2, EX.O3],
                   EX.p3() => [~B<foo>, ~L"bar"]
                 }
               )
             ) == Description.new(EX.S, init: {EX.S, EX.p1(), EX.O2})
    end
  end

  describe "delete_predicates" do
    setup do
      {:ok,
       empty_description: Description.new(EX.S),
       description1: Description.new(EX.S, init: {EX.S, EX.p(), [EX.O1, EX.O2]}),
       description2:
         Description.new(EX.S,
           init: [
             {EX.P1, [EX.O1, EX.O2]},
             {EX.p2(), [~B<foo>, ~L"bar"]}
           ]
         )}
    end

    test "a single property",
         %{
           empty_description: empty_description,
           description1: description1,
           description2: description2
         } do
      assert Description.delete_predicates(description1, EX.p()) == empty_description

      assert Description.delete_predicates(description2, EX.P1) ==
               Description.new(EX.S, init: {EX.S, EX.p2(), [~B<foo>, ~L"bar"]})
    end

    test "a list of properties",
         %{
           empty_description: empty_description,
           description1: description1,
           description2: description2
         } do
      assert Description.delete_predicates(description1, [EX.p()]) == empty_description

      assert Description.delete_predicates(description2, [EX.P1, EX.p2(), EX.p3()]) ==
               empty_description
    end
  end

  describe "update/4" do
    test "list values returned from the update function become new coerced objects of the predicate" do
      assert Description.new(EX.S, init: {EX.S, EX.P, [EX.O1, EX.O2]})
             |> Description.update(
               EX.P,
               fn [_object | other] -> [EX.O3 | other] end
             ) ==
               Description.new(EX.S, init: {EX.S, EX.P, [EX.O3, EX.O2]})
    end

    test "single values returned from the update function becomes new object of the predicate" do
      assert Description.new(EX.S, init: {EX.S, EX.P, [EX.O1, EX.O2]})
             |> Description.update(EX.P, fn _ -> EX.O3 end) ==
               Description.new(EX.S, init: {EX.S, EX.P, EX.O3})
    end

    test "returning an empty list or nil from the update function causes a removal of the predications" do
      description =
        EX.S
        |> EX.p(EX.O1, EX.O2)

      assert description
             |> Description.update(EX.p(), fn _ -> [] end) ==
               Description.new(EX.S)

      assert description
             |> Description.update(EX.p(), fn _ -> nil end) ==
               Description.new(EX.S)
    end

    test "when the property is not present the initial object value is added for the predicate and the update function not called" do
      fun = fn _ -> raise "should not be called" end

      assert Description.new(EX.S) |> Description.update(EX.P, EX.O, fun) ==
               Description.new(EX.S, init: {EX.S, EX.P, EX.O})

      assert Description.new(EX.S) |> Description.update(EX.P, fun) ==
               Description.new(EX.S)
    end
  end

  test "pop" do
    assert Description.pop(Description.new(EX.S)) == {nil, Description.new(EX.S)}

    {triple, desc} = Description.new(EX.S, init: {EX.S, EX.p(), EX.O}) |> Description.pop()
    assert {iri(EX.S), iri(EX.p()), iri(EX.O)} == triple
    assert Enum.count(desc.predications) == 0

    {{subject, predicate, _}, desc} =
      Description.new(EX.S, init: [{EX.S, EX.p(), EX.O1}, {EX.S, EX.p(), EX.O2}])
      |> Description.pop()

    assert {subject, predicate} == {iri(EX.S), iri(EX.p())}
    assert Enum.count(desc.predications) == 1

    {{subject, _, _}, desc} =
      Description.new(EX.S, init: [{EX.S, EX.p1(), EX.O1}, {EX.S, EX.p2(), EX.O2}])
      |> Description.pop()

    assert subject == iri(EX.S)
    assert Enum.count(desc.predications) == 1
  end

  test "include?/2" do
    desc =
      Description.new(EX.S,
        init: [
          {EX.p1(), [EX.O1, EX.O2]},
          {EX.p2(), EX.O3},
          {EX.p3(), [~B<foo>, ~L"bar"]}
        ]
      )

    assert Description.include?(desc, {EX.p1(), EX.O2})
    assert Description.include?(desc, {EX.p1(), [EX.O1, EX.O2]})
    assert Description.include?(desc, [{EX.p1(), [EX.O1]}, {EX.p2(), EX.O3}])
    assert Description.include?(desc, %{EX.p1() => [EX.O1, EX.O2], EX.p2() => EX.O3})

    assert Description.include?(
             desc,
             Description.new(EX.S, init: %{EX.p1() => [EX.O1, EX.O2], EX.p2() => EX.O3})
           )

    refute Description.include?(desc, {EX.p4(), EX.O1})
    refute Description.include?(desc, {EX.p1(), EX.O3})
    refute Description.include?(desc, {EX.p1(), [EX.O1, EX.O3]})
  end

  test "values/1" do
    assert Description.new(EX.s()) |> Description.values() == %{}

    assert Description.new(EX.s(), init: {EX.s(), EX.p(), ~L"Foo"}) |> Description.values() ==
             %{RDF.Term.value(EX.p()) => ["Foo"]}
  end

  test "values/2" do
    mapping = fn
      {:predicate, predicate} ->
        predicate |> to_string() |> String.split("/") |> List.last() |> String.to_atom()

      {_, term} ->
        RDF.Term.value(term)
    end

    assert Description.new(EX.s()) |> Description.values(mapping) == %{}

    assert Description.new(EX.s(), init: {EX.s(), EX.p(), ~L"Foo"}) |> Description.values(mapping) ==
             %{p: ["Foo"]}
  end

  describe "take/2" do
    test "with a non-empty property list" do
      assert Description.new(EX.S, init: [{EX.S, EX.p1(), EX.O1}, {EX.S, EX.p2(), EX.O2}])
             |> Description.take([EX.p2(), EX.p3()]) ==
               Description.new(EX.S, init: {EX.S, EX.p2(), EX.O2})
    end

    test "with an empty property list" do
      assert Description.new(EX.S, init: [{EX.S, EX.p1(), EX.O1}, {EX.S, EX.p2(), EX.O2}])
             |> Description.take([]) == Description.new(EX.S)
    end

    test "with nil" do
      assert Description.new(EX.S, init: [{EX.S, EX.p1(), EX.O1}, {EX.S, EX.p2(), EX.O2}])
             |> Description.take(nil) ==
               Description.new(EX.S, init: [{EX.S, EX.p1(), EX.O1}, {EX.S, EX.p2(), EX.O2}])
    end
  end

  test "equal/2" do
    assert Description.new(EX.S, init: {EX.S, EX.p(), EX.O})
           |> Description.equal?(Description.new(EX.S, init: {EX.S, EX.p(), EX.O}))

    refute Description.new(EX.S, init: {EX.S, EX.p(), EX.O})
           |> Description.equal?(Description.new(EX.S, init: {EX.S, EX.p(), EX.O2}))
  end

  describe "Enumerable protocol" do
    test "Enum.count" do
      assert Enum.count(Description.new(EX.foo())) == 0
      assert Enum.count(Description.new(EX.S, init: {EX.S, EX.p(), EX.O})) == 1

      assert Enum.count(
               Description.new(EX.S, init: [{EX.S, EX.p(), EX.O1}, {EX.S, EX.p(), EX.O2}])
             ) == 2
    end

    test "Enum.member?" do
      refute Enum.member?(Description.new(EX.S), {iri(EX.S), EX.p(), iri(EX.O)})
      assert Enum.member?(Description.new(EX.S, init: {EX.S, EX.p(), EX.O}), {EX.S, EX.p(), EX.O})

      desc =
        Description.new(EX.Subject,
          init: [
            {EX.Subject, EX.predicate1(), EX.Object1},
            {EX.Subject, EX.predicate2(), EX.Object2},
            {EX.predicate2(), EX.Object3}
          ]
        )

      assert Enum.member?(desc, {EX.Subject, EX.predicate1(), EX.Object1})
      assert Enum.member?(desc, {EX.Subject, EX.predicate2(), EX.Object2})
      assert Enum.member?(desc, {EX.Subject, EX.predicate2(), EX.Object3})
      refute Enum.member?(desc, {EX.Subject, EX.predicate1(), EX.Object2})
    end

    test "Enum.reduce" do
      desc =
        Description.new(EX.Subject,
          init: [
            {EX.Subject, EX.predicate1(), EX.Object1},
            {EX.Subject, EX.predicate2(), EX.Object2},
            {EX.predicate2(), EX.Object3}
          ]
        )

      assert desc ==
               Enum.reduce(desc, description(), fn triple, acc ->
                 acc |> Description.add(triple)
               end)
    end
  end

  describe "Collectable protocol" do
    test "with a map" do
      map = %{
        EX.predicate1() => EX.Object1,
        EX.predicate2() => EX.Object2
      }

      assert Enum.into(map, Description.new(EX.Subject)) ==
               Description.new(EX.Subject, init: map)
    end

    test "with a list of triples" do
      triples = [
        {EX.Subject, EX.predicate1(), EX.Object1},
        {EX.Subject, EX.predicate2(), EX.Object2}
      ]

      assert Enum.into(triples, Description.new(EX.Subject)) ==
               Description.new(EX.Subject, init: triples)
    end

    test "with a list of predicate-object pairs" do
      pairs = [
        {EX.predicate1(), EX.Object1},
        {EX.predicate2(), EX.Object2}
      ]

      assert Enum.into(pairs, Description.new(EX.Subject)) ==
               Description.new(EX.Subject, init: pairs)
    end

    test "with a list of lists" do
      lists = [
        [EX.Subject, EX.predicate1(), EX.Object1],
        [EX.Subject, EX.predicate2(), EX.Object2]
      ]

      assert Enum.into(lists, Description.new(EX.Subject)) ==
               Description.new(EX.Subject, init: Enum.map(lists, &List.to_tuple/1))
    end
  end

  describe "Access behaviour" do
    test "access with the [] operator" do
      assert Description.new(EX.Subject)[EX.predicate()] == nil

      assert Description.new(EX.Subject, init: {EX.Subject, EX.predicate(), EX.Object})[
               EX.predicate()
             ] == [
               iri(EX.Object)
             ]

      assert Description.new(EX.Subject, init: {EX.Subject, EX.Predicate, EX.Object})[
               EX.Predicate
             ] == [
               iri(EX.Object)
             ]

      assert Description.new(EX.Subject, init: {EX.Subject, EX.predicate(), EX.Object})[
               "http://example.com/predicate"
             ] == [iri(EX.Object)]

      assert Description.new(EX.Subject,
               init: [
                 {EX.Subject, EX.predicate1(), EX.Object1},
                 {EX.Subject, EX.predicate1(), EX.Object2},
                 {EX.Subject, EX.predicate2(), EX.Object3}
               ]
             )[EX.predicate1()] ==
               [iri(EX.Object1), iri(EX.Object2)]
    end
  end
end
