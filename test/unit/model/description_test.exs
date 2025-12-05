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
      assert description_of_subject(Description.new(EX.Bar), RDF.iri(EX.Bar))
    end

    test "with a BlankNode subject" do
      assert description_of_subject(Description.new(bnode(:foo)), bnode(:foo))
    end

    test "with another description" do
      existing_description = description({EX.Subject, EX.predicate(), EX.Object})
      new_description = Description.new(existing_description)
      assert description_of_subject(new_description, RDF.iri(EX.Subject))

      refute description_includes_predication(
               new_description,
               {EX.predicate(), RDF.iri(EX.Object)}
             )
    end

    test "with init data" do
      desc = Description.new(EX.Subject, init: {EX.Subject, EX.predicate(), EX.Object})
      assert description_of_subject(desc, RDF.iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate(), RDF.iri(EX.Object)})

      desc =
        Description.new(
          EX.Subject,
          init: [
            {EX.Subject, EX.predicate1(), EX.Object1},
            {EX.Subject, EX.predicate2(), EX.Object2}
          ]
        )

      assert description_of_subject(desc, RDF.iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate1(), RDF.iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), RDF.iri(EX.Object2)})

      other_desc = Description.new(EX.Subject2, init: {EX.Subject2, EX.predicate(), EX.Object})
      desc = Description.new(EX.Subject, init: other_desc)
      assert description_of_subject(desc, RDF.iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate(), RDF.iri(EX.Object)})

      desc =
        Description.new(
          EX.Subject,
          init: %{
            p1: EX.Object1,
            p2: EX.Object2
          },
          context: %{
            p1: EX.predicate1(),
            p2: EX.predicate2()
          }
        )

      assert description_of_subject(desc, RDF.iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate1(), RDF.iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), RDF.iri(EX.Object2)})
    end

    test "with an initializer function" do
      desc = Description.new(EX.Subject, init: fn -> {EX.Subject, EX.predicate(), EX.Object} end)
      assert description_of_subject(desc, RDF.iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate(), RDF.iri(EX.Object)})
    end
  end

  test "subject/1" do
    assert Description.subject(description()) == description().subject
  end

  test "change_subject/2" do
    assert Description.change_subject(description(), EX.NewSubject).subject ==
             RDF.iri(EX.NewSubject)
  end

  describe "add/3" do
    test "with a triple" do
      assert Description.add(
               description(),
               {RDF.iri(EX.Subject), EX.predicate(), RDF.iri(EX.Object)}
             )
             |> description_includes_predication({EX.predicate(), RDF.iri(EX.Object)})

      assert Description.add(description(), {RDF.iri(EX.Subject), EX.predicate(), bnode(:foo)})
             |> description_includes_predication({EX.predicate(), bnode(:foo)})

      assert Description.add(description(), {RDF.iri(EX.Subject), EX.predicate(), literal(42)})
             |> description_includes_predication({EX.predicate(), literal(42)})
    end

    test "with a quad" do
      assert Description.add(
               description(),
               {RDF.iri(EX.Subject), EX.predicate(), RDF.iri(EX.Object), EX.Graph}
             )
             |> description_includes_predication({EX.predicate(), RDF.iri(EX.Object)})

      assert Description.add(description(), {EX.Subject, EX.predicate(), 42, nil})
             |> description_includes_predication({EX.predicate(), literal(42)})
    end

    test "with a predicate-object tuple" do
      assert Description.add(description(), {EX.predicate(), RDF.iri(EX.Object)})
             |> description_includes_predication({EX.predicate(), RDF.iri(EX.Object)})
    end

    test "with a predicate-object tuple and a list of objects" do
      desc = Description.add(description(), {EX.p(), [RDF.iri(EX.O1), RDF.iri(EX.O2)]})
      assert description_includes_predication(desc, {EX.p(), RDF.iri(EX.O1)})
      assert description_includes_predication(desc, {EX.p(), RDF.iri(EX.O2)})
    end

    test "with a predicate-object tuple and an empty list of objects" do
      assert Description.add(description(), {EX.p(), []}) ==
               description()
    end

    test "with a list of predicate-object tuples" do
      desc =
        Description.add(description(), [
          {EX.predicate(), EX.Object1},
          {EX.predicate(), EX.Object2}
        ])

      assert description_includes_predication(desc, {EX.predicate(), RDF.iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate(), RDF.iri(EX.Object2)})

      desc =
        Description.add(description(), [
          {EX.p1(), EX.O1},
          {EX.p2(), [EX.O2, ~L"foo", "bar", 42]}
        ])

      assert description_includes_predication(desc, {EX.p1(), RDF.iri(EX.O1)})
      assert description_includes_predication(desc, {EX.p2(), RDF.iri(EX.O2)})
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

      assert description_includes_predication(desc, {EX.predicate1(), RDF.iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), RDF.iri(EX.Object2)})

      desc =
        Description.add(description(), [
          {EX.Subject, EX.predicate1(), EX.Object1},
          {EX.Subject, EX.predicate2(), [EX.Object2, EX.Object3]}
        ])

      assert description_includes_predication(desc, {EX.predicate1(), RDF.iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), RDF.iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate2(), RDF.iri(EX.Object3)})
    end

    test "a list of mixed triples and predicate-object-pairs" do
      desc =
        Description.add(description(), [
          {EX.predicate(), EX.Object1},
          {EX.Subject, EX.predicate(), EX.Object2},
          {EX.Other, EX.predicate(), EX.Object3}
        ])

      assert description_of_subject(desc, RDF.iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate(), RDF.iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate(), RDF.iri(EX.Object2)})
      refute description_includes_predication(desc, {EX.predicate(), RDF.iri(EX.Object3)})
    end

    test "with a description map with coercible RDF terms" do
      desc =
        description([{EX.predicate1(), EX.Object1}, {EX.predicate2(), EX.Object2}])
        |> Description.add(%{EX.predicate3() => EX.Object3})

      assert description_of_subject(desc, RDF.iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate1(), RDF.iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), RDF.iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate3(), RDF.iri(EX.Object3)})

      desc =
        Description.add(desc, %{
          EX.predicate1() => EX.Object1,
          EX.predicate2() => [EX.Object2, 42],
          EX.predicate3() => [bnode(:foo)]
        })

      assert Description.count(desc) == 5
      assert description_includes_predication(desc, {EX.predicate1(), RDF.iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), RDF.iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate2(), literal(42)})
      assert description_includes_predication(desc, {EX.predicate3(), RDF.iri(EX.Object3)})
      assert description_includes_predication(desc, {EX.predicate3(), bnode(:foo)})
    end

    test "a map of predications with non-coercible RDF terms" do
      assert_raise RDF.IRI.InvalidError, fn ->
        Description.add(description(), %{"not a IRI" => RDF.iri(EX.Object)})
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

      assert description_of_subject(desc, RDF.iri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate1(), RDF.iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), RDF.iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate3(), RDF.iri(EX.Object3)})

      desc =
        Description.add(
          desc,
          Description.new(EX.Other, init: {EX.Other, EX.predicate1(), EX.Object4})
        )

      assert description_includes_predication(desc, {EX.predicate1(), RDF.iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), RDF.iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate3(), RDF.iri(EX.Object3)})
      assert description_includes_predication(desc, {EX.predicate1(), RDF.iri(EX.Object4)})
    end

    test "with a context" do
      context =
        PropertyMap.new(
          p1: EX.p1(),
          p2: EX.p2()
        )

      assert Description.add(description(), {RDF.iri(EX.Subject), :p, literal(42)},
               context: [p: EX.predicate()]
             )
             |> description_includes_predication({EX.predicate(), literal(42)})

      assert Description.add(description(), {RDF.iri(EX.Subject), :p, literal(42), EX.Graph},
               context: %{p: EX.predicate()}
             )
             |> description_includes_predication({EX.predicate(), literal(42)})

      desc =
        Description.add(
          description(),
          [
            p1: EX.O1,
            p2: [EX.O2, ~L"foo", "bar", 42]
          ],
          context: context
        )

      assert description_includes_predication(desc, {EX.p1(), RDF.iri(EX.O1)})
      assert description_includes_predication(desc, {EX.p2(), RDF.iri(EX.O2)})
      assert description_includes_predication(desc, {EX.p2(), ~L"foo"})
      assert description_includes_predication(desc, {EX.p2(), ~L"bar"})
      assert description_includes_predication(desc, {EX.p2(), RDF.literal(42)})

      desc =
        Description.add(
          description(),
          %{
            p1: EX.Object1,
            p2: [EX.Object2, 42, bnode(:foo)]
          },
          context: context
        )

      assert Description.count(desc) == 4
      assert description_includes_predication(desc, {EX.p1(), RDF.iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.p2(), RDF.iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.p2(), literal(42)})
      assert description_includes_predication(desc, {EX.p2(), bnode(:foo)})

      desc =
        Description.add(
          description(),
          [
            {:p1, EX.Object1},
            {EX.Subject, :p2, EX.Object2},
            %{p2: EX.Object3},
            EX.predicate(EX.Other, EX.Object4)
          ],
          context: context
        )

      assert Description.count(desc) == 4
      assert description_of_subject(desc, RDF.iri(EX.Subject))
      assert description_includes_predication(desc, {EX.p1(), RDF.iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.p2(), RDF.iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.p2(), RDF.iri(EX.Object3)})
      assert description_includes_predication(desc, {EX.predicate(), RDF.iri(EX.Object4)})

      desc = Description.add(description(), [type: EX.Class], context: RDF.NS.RDF)
      assert Description.count(desc) == 1
      assert description_includes_predication(desc, {RDF.type(), RDF.iri(EX.Class)})
    end

    test "triples with another subject are ignored" do
      assert empty_description(
               Description.add(description(), {EX.Other, EX.predicate(), RDF.iri(EX.Object)})
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
             |> description_includes_predication({RDF.iri(EX.P), RDF.iri(EX.O)})

      assert Description.add(description(), {"http://example.com/predicate", EX.Object})
             |> description_includes_predication({EX.predicate(), RDF.iri(EX.Object)})

      desc = Description.add(description(), {"http://example.com/predicate", [42, true]})
      assert description_includes_predication(desc, {EX.predicate(), literal(42)})
      assert description_includes_predication(desc, {EX.predicate(), literal(true)})
    end

    test "non-coercible Triple elements are causing an error" do
      assert_raise RDF.IRI.InvalidError, fn ->
        Description.add(description(), {"not a IRI", RDF.iri(EX.Object)})
      end

      assert_raise RDF.Literal.InvalidError, fn ->
        Description.add(description(), {EX.prop(), self()})
      end
    end

    test "structs are causing an error" do
      assert_raise FunctionClauseError, fn ->
        Description.add(description(), Date.utc_today())
      end

      assert_raise FunctionClauseError, fn ->
        Description.add(description(), RDF.graph())
      end

      assert_raise FunctionClauseError, fn ->
        Description.add(description(), RDF.dataset())
      end
    end
  end

  describe "put/3" do
    test "with a triple" do
      desc =
        description({RDF.iri(EX.Subject), EX.predicate(), RDF.iri(EX.Object1)})
        |> Description.put({RDF.iri(EX.Subject), EX.predicate(), RDF.iri(EX.Object2)})

      assert Description.count(desc) == 1
      assert description_includes_predication(desc, {EX.predicate(), RDF.iri(EX.Object2)})
    end

    test "with a quad" do
      desc =
        description({RDF.iri(EX.Subject), EX.predicate(), RDF.iri(EX.Object1)})
        |> Description.put({RDF.iri(EX.Subject), EX.predicate(), RDF.iri(EX.Object2), EX.Graph})

      assert Description.count(desc) == 1
      assert description_includes_predication(desc, {EX.predicate(), RDF.iri(EX.Object2)})
    end

    test "with a predicate-object tuple" do
      desc =
        description({RDF.iri(EX.Subject), EX.p(), RDF.iri(EX.O1)})
        |> Description.put({EX.p(), [RDF.iri(EX.O2), RDF.iri(EX.O3)]})

      assert Description.count(desc) == 2
      assert description_includes_predication(desc, {EX.p(), RDF.iri(EX.O2)})
      assert description_includes_predication(desc, {EX.p(), RDF.iri(EX.O3)})
    end

    test "with a list of predicate-object tuples" do
      desc =
        description({RDF.iri(EX.Subject), EX.p2(), RDF.iri(EX.O1)})
        |> Description.put([
          {EX.p1(), EX.O1},
          {EX.p2(), [EX.O2]},
          {EX.p2(), [~L"foo", "bar", 42]}
        ])

      assert Description.count(desc) == 5
      assert description_includes_predication(desc, {EX.p1(), RDF.iri(EX.O1)})
      assert description_includes_predication(desc, {EX.p2(), RDF.iri(EX.O2)})
      assert description_includes_predication(desc, {EX.p2(), ~L"foo"})
      assert description_includes_predication(desc, {EX.p2(), ~L"bar"})
      assert description_includes_predication(desc, {EX.p2(), RDF.literal(42)})
    end

    test "with a list of triples" do
      desc =
        description([
          {RDF.iri(EX.Subject), EX.predicate1(), RDF.iri(EX.Object)},
          {RDF.iri(EX.Subject), EX.predicate2(), RDF.iri(EX.Object)}
        ])
        |> Description.put([
          {EX.Subject, EX.predicate1(), EX.Object1},
          {EX.Subject, EX.predicate2(), [EX.Object2, EX.Object3]},
          {EX.Subject, EX.predicate2(), [EX.Object4]}
        ])

      assert Description.count(desc) == 4
      assert description_includes_predication(desc, {EX.predicate1(), RDF.iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), RDF.iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate2(), RDF.iri(EX.Object3)})
      assert description_includes_predication(desc, {EX.predicate2(), RDF.iri(EX.Object4)})
    end

    test "with a description map with coercible RDF terms" do
      desc =
        description([{EX.predicate1(), EX.Object1}, {EX.predicate2(), EX.Object2}])
        |> Description.put(%{
          EX.predicate2() => [EX.Object3, 42],
          EX.predicate3() => bnode(:foo)
        })

      assert Description.count(desc) == 4
      assert description_includes_predication(desc, {EX.predicate1(), RDF.iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2(), RDF.iri(EX.Object3)})
      assert description_includes_predication(desc, {EX.predicate2(), literal(42)})
      assert description_includes_predication(desc, {EX.predicate3(), bnode(:foo)})
      refute description_includes_predication(desc, {EX.predicate2(), RDF.iri(EX.Object2)})
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
      assert description_includes_predication(desc, {EX.predicate1(), RDF.iri(EX.Object4)})
      assert description_includes_predication(desc, {EX.predicate2(), RDF.iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.predicate3(), RDF.iri(EX.Object3)})
    end

    test "with a description on another subject" do
      desc = description([{EX.predicate1(), EX.Object1}, {EX.predicate2(), EX.Object2}])

      assert Description.put(
               desc,
               Description.new(EX.Other, init: {EX.Other, EX.predicate(), RDF.iri(EX.Object)})
             ) == desc
    end

    test "with a context" do
      desc =
        Description.put(
          description(),
          [
            {:p1, EX.Object1},
            {EX.Subject, :p2, EX.Object2},
            %{p3: EX.Object3},
            EX.predicate(EX.Other, EX.Object4)
          ],
          context: [
            p1: EX.p1(),
            p2: EX.p2(),
            p3: EX.p3()
          ]
        )

      assert Description.count(desc) == 4
      assert description_of_subject(desc, RDF.iri(EX.Subject))
      assert description_includes_predication(desc, {EX.p1(), RDF.iri(EX.Object1)})
      assert description_includes_predication(desc, {EX.p2(), RDF.iri(EX.Object2)})
      assert description_includes_predication(desc, {EX.p3(), RDF.iri(EX.Object3)})
      assert description_includes_predication(desc, {EX.predicate(), RDF.iri(EX.Object4)})
    end

    test "triples with another subject are ignored" do
      assert empty_description(
               Description.put(description(), {EX.Other, EX.predicate(), RDF.iri(EX.Object)})
             )
    end

    test "structs are causing an error" do
      assert_raise FunctionClauseError, fn ->
        Description.put(description(), Date.utc_today())
      end

      assert_raise FunctionClauseError, fn ->
        Description.put(description(), RDF.graph())
      end

      assert_raise FunctionClauseError, fn ->
        Description.put(description(), RDF.dataset())
      end
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

    test "predicate-object tuples",
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

    test "statements",
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

    test "statements with another subject",
         %{
           empty_description: empty_description,
           description1: description1,
           description2: description2
         } do
      assert Description.delete(empty_description, {EX.Other, EX.p(), EX.O}) == empty_description
      assert Description.delete(description1, {EX.Other, EX.p(), EX.O}) == description1
      assert Description.delete(description2, {EX.Other, EX.p(), EX.O2}) == description2
    end

    test "predicate-object tuples with object lists",
         %{
           empty_description: empty_description,
           description1: description1,
           description2: description2
         } do
      assert Description.delete(empty_description, {EX.p(), [EX.O1, EX.O2]}) == empty_description
      assert Description.delete(description1, {EX.p(), [EX.O, EX.O2]}) == empty_description
      assert Description.delete(description2, {EX.p(), [EX.O1, EX.O2]}) == empty_description
      assert Description.delete(description2, {EX.p(), [EX.O1, EX.O2]}) == empty_description
    end

    test "list of statements",
         %{empty_description: empty_description, description3: description3} do
      assert Description.delete(empty_description, [{EX.p(), [EX.O1, EX.O2]}]) ==
               empty_description

      assert Description.delete(description3, [
               {EX.p1(), EX.O1},
               {EX.p2(), [EX.O2, EX.O3]},
               {EX.S, EX.p3(), [~B<foo>]},
               {EX.S, EX.p3(), ~L"bar"}
             ]) == Description.new(EX.S, init: {EX.S, EX.p1(), EX.O2})
    end

    test "description maps",
         %{empty_description: empty_description, description3: description3} do
      assert Description.delete(empty_description, %{EX.p() => EX.O1}) == empty_description

      assert Description.delete(description3, %{
               EX.p1() => EX.O1,
               EX.p2() => [EX.O2, EX.O3],
               EX.p3() => [~B<foo>, ~L"bar"]
             }) == Description.new(EX.S, init: {EX.S, EX.p1(), EX.O2})
    end

    test "another description",
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

    test "with a context", %{description3: description3} do
      desc =
        Description.delete(
          description3,
          [
            {:p1, EX.O1},
            {EX.S, :p2, EX.O3},
            %{p3: ~B<foo>},
            EX.p3(EX.S, ~L"bar")
          ],
          context: [
            p1: EX.p1(),
            p2: EX.p2(),
            p3: EX.p3()
          ]
        )

      assert Description.count(desc) == 1
      assert description_of_subject(desc, RDF.iri(EX.S))
      assert description_includes_predication(desc, {EX.p1(), RDF.iri(EX.O2)})
    end

    test "structs are causing an error" do
      assert_raise FunctionClauseError, fn ->
        Description.delete(description(), Date.utc_today())
      end

      assert_raise FunctionClauseError, fn ->
        Description.delete(description(), RDF.graph())
      end

      assert_raise FunctionClauseError, fn ->
        Description.delete(description(), RDF.dataset())
      end
    end
  end

  describe "delete with :on_graph_mismatch option" do
    setup do
      {:ok, description: Description.new(EX.S, init: {EX.S, EX.p(), EX.O})}
    end

    test "default (:warn) logs warning and deletes", %{description: description} do
      import ExUnit.CaptureLog

      log =
        capture_log(fn ->
          assert Description.delete(description, {EX.S, EX.p(), EX.O, EX.G}) ==
                   Description.new(EX.S)
        end)

      assert log =~ "Graph name"
      assert log =~ "ignored"
    end

    test ":ignore deletes without warning", %{description: description} do
      import ExUnit.CaptureLog

      log =
        capture_log(fn ->
          assert Description.delete(description, {EX.S, EX.p(), EX.O, EX.G},
                   on_graph_mismatch: :ignore
                 ) ==
                   Description.new(EX.S)
        end)

      assert log == ""
    end

    test ":skip does not delete", %{description: description} do
      assert Description.delete(description, {EX.S, EX.p(), EX.O, EX.G}, on_graph_mismatch: :skip) ==
               description
    end

    test ":error raises ArgumentError", %{description: description} do
      assert_raise ArgumentError, ~r/graph name/i, fn ->
        Description.delete(description, {EX.S, EX.p(), EX.O, EX.G}, on_graph_mismatch: :error)
      end
    end

    test "nil graph name does not trigger mismatch", %{description: description} do
      import ExUnit.CaptureLog

      log =
        capture_log(fn ->
          assert Description.delete(description, {EX.S, EX.p(), EX.O, nil}) ==
                   Description.new(EX.S)
        end)

      assert log == ""
    end

    test "with list of statements - skips only mismatched quads", %{description: _description} do
      desc =
        Description.new(EX.S,
          init: [
            {EX.p1(), EX.O1},
            {EX.p2(), EX.O2}
          ]
        )

      assert Description.delete(
               desc,
               [
                 {EX.S, EX.p1(), EX.O1, EX.G},
                 {EX.S, EX.p2(), EX.O2, nil}
               ],
               on_graph_mismatch: :skip
             ) ==
               Description.new(EX.S, init: {EX.p1(), EX.O1})
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

  describe "update_all_predicates/4" do
    test "list values returned from the update function become new coerced objects of the predicate" do
      assert Description.new(EX.S, init: {EX.S, EX.P, [EX.O1, EX.O2]})
             |> Description.update_all_predicates(fn
               {term_to_iri(EX.P), [term_to_iri(EX.O1), term_to_iri(EX.O2)]} ->
                 [EX.O3, EX.O4]
             end) ==
               Description.new(EX.S, init: {EX.S, EX.P, [EX.O3, EX.O4]})
    end

    test "single values returned from the update function becomes new object of the predicate" do
      assert Description.new(EX.S, init: {EX.S, EX.P, [EX.O1, EX.O2]})
             |> Description.update_all_predicates(fn
               {term_to_iri(EX.P), [term_to_iri(EX.O1), term_to_iri(EX.O2)]} ->
                 EX.O3
             end) ==
               Description.new(EX.S, init: {EX.S, EX.P, [EX.O3]})
    end

    test "returning an empty list or nil from the update function causes a removal of the predications" do
      description = EX.S |> EX.p(EX.O)

      assert description
             |> Description.update_all_predicates(fn {term_to_iri(EX.p()), [term_to_iri(EX.O)]} ->
               []
             end) ==
               Description.new(EX.S)

      assert description
             |> Description.update_all_predicates(fn _ -> nil end) ==
               Description.new(EX.S)
    end
  end

  describe "update_all_objects/4" do
    test "list values returned from the update function become new coerced objects of the predicate" do
      assert Description.new(EX.S, init: {EX.S, EX.P, [EX.O1, EX.O2]})
             |> Description.update_all_objects(fn
               term_to_iri(EX.P), term_to_iri(EX.O1) -> [EX.O3, EX.O4]
               term_to_iri(EX.P), term_to_iri(EX.O2) -> [EX.O5]
             end) ==
               Description.new(EX.S, init: {EX.S, EX.P, [EX.O3, EX.O4, EX.O5]})
    end

    test "single values returned from the update function becomes new object of the predicate" do
      assert Description.new(EX.S, init: {EX.S, EX.P, [EX.O1, EX.O2]})
             |> Description.update_all_objects(fn
               term_to_iri(EX.P), term_to_iri(EX.O1) -> EX.O3
               term_to_iri(EX.P), term_to_iri(EX.O2) -> EX.O4
             end) ==
               Description.new(EX.S, init: {EX.S, EX.P, [EX.O3, EX.O4]})
    end

    test "returning an empty list or nil from the update function causes a removal of the predications" do
      description = EX.S |> EX.p([EX.O1, EX.O2])

      assert description
             |> Description.update_all_objects(fn
               term_to_iri(EX.p()), term_to_iri(EX.O1) -> [EX.O]
               term_to_iri(EX.p()), term_to_iri(EX.O2) -> []
             end) ==
               EX.S |> EX.p(EX.O)

      assert description
             |> Description.update_all_objects(fn _, _ -> nil end) ==
               Description.new(EX.S)
    end
  end

  describe "rename_resource/3" do
    test "renaming" do
      assert EX.s()
             |> EX.p1([EX.o1()])
             |> EX.p2([EX.s(), EX.o2()])
             |> EX.s([EX.s(), EX.o3()])
             |> Description.rename_resource(EX.s(), EX.new()) ==
               EX.new()
               |> EX.p1([EX.o1()])
               |> EX.p2([EX.new(), EX.o2()])
               |> EX.new([EX.new(), EX.o3()])
    end

    test "coercion" do
      assert EX.S
             |> EX.p1([EX.o1()])
             |> EX.p2([EX.S, EX.o2()])
             |> Description.add({EX.S, [EX.S, EX.o3()]})
             |> Description.rename_resource(EX.S, EX.New) ==
               EX.New
               |> EX.p1([EX.o1()])
               |> EX.p2([EX.New, EX.o2()])
               |> Description.add({EX.New, [EX.New, EX.o3()]})
    end

    test "blank node renames" do
      assert EX.S
             |> EX.p1([EX.o1()])
             |> EX.p2([EX.S, EX.o2()])
             |> Description.add({EX.S, [EX.S, EX.o3()]})
             |> Description.rename_resource(EX.S, RDF.bnode("new")) ==
               RDF.bnode("new")
               |> EX.p1([EX.o1()])
               |> EX.p2([RDF.bnode("new"), EX.o2()])
               |> Description.add({RDF.bnode("new"), [RDF.bnode("new"), EX.o3()]})

      assert RDF.bnode("old")
             |> EX.p1([EX.o1()])
             |> EX.p2([RDF.bnode("old"), EX.o2()])
             |> Description.add({RDF.bnode("old"), [RDF.bnode("old"), EX.o3()]})
             |> Description.rename_resource(RDF.bnode("old"), EX.S) ==
               EX.S
               |> EX.p1([EX.o1()])
               |> EX.p2([EX.S, EX.o2()])
               |> Description.add({EX.S, [EX.S, EX.o3()]})

      assert RDF.bnode("old")
             |> EX.p1([EX.o1()])
             |> EX.p2([RDF.bnode("old"), EX.o2()])
             |> Description.add({RDF.bnode("old"), [RDF.bnode("old"), EX.o3()]})
             |> Description.rename_resource(RDF.bnode("old"), RDF.bnode("new")) ==
               RDF.bnode("new")
               |> EX.p1([EX.o1()])
               |> EX.p2([RDF.bnode("new"), EX.o2()])
               |> Description.add({RDF.bnode("new"), [RDF.bnode("new"), EX.o3()]})
    end

    test "old and new id are equal" do
      description = EX.S |> EX.p(EX.O)
      assert description |> Description.rename_resource(EX.S, EX.S) == description
      assert description |> Description.rename_resource(RDF.iri(EX.S), EX.S) == description
    end
  end

  test "pop" do
    assert Description.pop(Description.new(EX.S)) == {nil, Description.new(EX.S)}

    {triple, desc} = Description.new(EX.S, init: {EX.S, EX.p(), EX.O}) |> Description.pop()
    assert {RDF.iri(EX.S), RDF.iri(EX.p()), RDF.iri(EX.O)} == triple
    assert Enum.empty?(desc.predications)

    {{subject, predicate, _}, desc} =
      Description.new(EX.S, init: [{EX.S, EX.p(), EX.O1}, {EX.S, EX.p(), EX.O2}])
      |> Description.pop()

    assert {subject, predicate} == {RDF.iri(EX.S), RDF.iri(EX.p())}
    assert Enum.count(desc.predications) == 1

    {{subject, _, _}, desc} =
      Description.new(EX.S, init: [{EX.S, EX.p1(), EX.O1}, {EX.S, EX.p2(), EX.O2}])
      |> Description.pop()

    assert subject == RDF.iri(EX.S)
    assert Enum.count(desc.predications) == 1
  end

  test "first/3" do
    assert EX.S |> EX.p(EX.O) |> Description.first(EX.p()) == RDF.iri(EX.O)
    assert EX.S |> EX.p(EX.O1, EX.O2) |> Description.first(EX.p()) == RDF.iri(EX.O1)
    assert EX.S |> EX.p(EX.O1, EX.O2) |> Description.first(EX.missing()) == nil
    assert EX.S |> EX.p(EX.O1, EX.O2) |> Description.first(EX.missing(), :default) == :default
    assert EX.S |> EX.p(false) |> Description.first(EX.p(), :default) == XSD.false()
  end

  test "statement_count/1" do
    assert Description.statement_count(Description.new(EX.S)) == 0
    assert Description.statement_count(description({EX.p(), EX.O})) == 1
  end

  test "empty?/1" do
    assert Description.empty?(Description.new(EX.S)) == true
    assert Description.empty?(description({EX.p(), EX.O})) == false
  end

  describe "include?/3" do
    test "valid cases" do
      desc =
        Description.new(EX.S,
          init: [
            {EX.p1(), [EX.O1, EX.O2]},
            {EX.p2(), EX.O3},
            {EX.p3(), [~B<foo>, ~L"bar"]}
          ]
        )

      assert Description.include?(desc, {EX.S, EX.p1(), EX.O2})
      assert Description.include?(desc, {EX.S, EX.p1(), EX.O2, EX.Graph})
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

      assert Description.include?(
               desc,
               %{
                 p1: [EX.O1, EX.O2],
                 p2: EX.O3,
                 p3: [~B<foo>, "bar"]
               },
               context: %{p1: EX.p1(), p2: EX.p2(), p3: EX.p3()}
             )
    end

    test "structs are causing an error" do
      assert_raise FunctionClauseError, fn ->
        Description.include?(description(), Date.utc_today())
      end

      assert_raise FunctionClauseError, fn ->
        Description.include?(description(), RDF.graph())
      end

      assert_raise FunctionClauseError, fn ->
        Description.include?(description(), RDF.dataset())
      end
    end
  end

  test "values/1" do
    assert Description.new(EX.s()) |> Description.values() == %{}

    assert Description.new(EX.s(), init: {EX.s(), EX.p(), ~L"Foo"}) |> Description.values() ==
             %{RDF.Term.value(EX.p()) => ["Foo"]}
  end

  test "values/2" do
    assert Description.new(EX.s(), init: {EX.s(), EX.p(), ~L"Foo"})
           |> Description.values(context: PropertyMap.new(p: EX.p())) ==
             %{p: ["Foo"]}

    assert Description.new(EX.s(), init: {EX.s(), EX.p(), ~L"Foo"})
           |> Description.values(context: %{p: EX.p()}) ==
             %{p: ["Foo"]}
  end

  test "map/2" do
    mapping = fn
      {:predicate, predicate} ->
        predicate |> to_string() |> String.split("/") |> List.last() |> String.to_atom()

      {_, term} ->
        RDF.Term.value(term)
    end

    assert Description.new(EX.s()) |> Description.map(mapping) == %{}

    assert Description.new(EX.s(), init: {EX.s(), EX.p(), ~L"Foo"}) |> Description.map(mapping) ==
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

  # This function relies on Map.intersect/3 that was added in Elixir v1.15
  if Version.match?(System.version(), ">= 1.15.0") do
    describe "intersection/2" do
      test "with description" do
        description = description({EX.p(), [EX.O1, EX.O2]})

        assert Description.intersection(description, description) == description

        assert Description.intersection(description, description({EX.p(), [EX.O2, EX.O3]})) ==
                 description({EX.p(), [EX.O2]})

        assert Description.intersection(description, description({EX.p(), [EX.Other]})) ==
                 description()

        assert Description.intersection(description, description({EX.other(), [EX.O1, EX.O2]})) ==
                 description()

        assert Description.intersection(
                 description,
                 EX.Other |> EX.p(EX.O1, EX.O2)
               ) ==
                 description()
      end

      test "with graph" do
        description = description({EX.p(), [EX.O1, EX.O2]})

        assert Description.intersection(description, Graph.new(description)) == description

        assert Description.intersection(
                 description,
                 Graph.new(description({EX.p(), [EX.O2, EX.O3]}))
               ) == description({EX.p(), [EX.O2]})

        assert Description.intersection(description, Graph.new({EX.Other, EX.p(), EX.O1})) ==
                 description()
      end

      test "with dataset" do
        description = description({EX.p(), [EX.O1, EX.O2]})

        assert Description.intersection(description, Dataset.new(description)) == description

        assert Description.intersection(
                 description,
                 Dataset.new(description({EX.p(), [EX.O2, EX.O3]}))
               ) == description({EX.p(), [EX.O2]})

        assert Description.intersection(description, Dataset.new({EX.Other, EX.p(), EX.O1})) ==
                 description()
      end

      test "with coercible data" do
        description = description({EX.p(), [EX.O1, EX.O2]})

        assert Description.intersection(description, Description.triples(description)) ==
                 description

        assert Description.intersection(
                 description,
                 {description.subject, EX.p(), [EX.O2, EX.O3]}
               ) == description({EX.p(), [EX.O2]})
      end
    end
  end

  test "equal/2" do
    assert Description.new(EX.S, init: {EX.S, EX.p(), EX.O})
           |> Description.equal?(Description.new(EX.S, init: {EX.S, EX.p(), EX.O}))

    refute Description.new(EX.S, init: {EX.S, EX.p(), EX.O})
           |> Description.equal?(Description.new(EX.S, init: {EX.S, EX.p(), EX.O2}))
  end

  test "triples/1" do
    assert Description.new(EX.Subject,
             init: [
               {EX.predicate1(), EX.Object1},
               {EX.predicate2(), EX.Object2},
               {EX.predicate2(), EX.Object3}
             ]
           )
           |> Description.triples() == [
             {RDF.iri(EX.Subject), EX.predicate1(), RDF.iri(EX.Object1)},
             {RDF.iri(EX.Subject), EX.predicate2(), RDF.iri(EX.Object2)},
             {RDF.iri(EX.Subject), EX.predicate2(), RDF.iri(EX.Object3)}
           ]
  end

  describe "Enumerable protocol" do
    test "Enum.count" do
      # credo:disable-for-next-line Credo.Check.Warning.ExpensiveEmptyEnumCheck
      assert Enum.count(Description.new(EX.foo())) == 0
      assert Enum.count(Description.new(EX.S, init: {EX.S, EX.p(), EX.O})) == 1

      assert Enum.count(
               Description.new(EX.S, init: [{EX.S, EX.p(), EX.O1}, {EX.S, EX.p(), EX.O2}])
             ) == 2
    end

    test "Enum.member?" do
      refute Enum.member?(Description.new(EX.S), {RDF.iri(EX.S), EX.p(), RDF.iri(EX.O)})
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

    test "Enum.at (for Enumerable.slice/1)" do
      assert Description.new(EX.S, init: {EX.S, EX.p(), EX.O})
             |> Enum.at(0) == {RDF.iri(EX.S), EX.p(), RDF.iri(EX.O)}
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
  end

  describe "Access behaviour" do
    test "access with the [] operator" do
      assert Description.new(EX.Subject)[EX.predicate()] == nil

      assert Description.new(EX.Subject, init: {EX.Subject, EX.predicate(), EX.Object})[
               EX.predicate()
             ] == [
               RDF.iri(EX.Object)
             ]

      assert Description.new(EX.Subject, init: {EX.Subject, EX.Predicate, EX.Object})[
               EX.Predicate
             ] == [
               RDF.iri(EX.Object)
             ]

      assert Description.new(EX.Subject, init: {EX.Subject, EX.predicate(), EX.Object})[
               "http://example.com/predicate"
             ] == [RDF.iri(EX.Object)]

      assert Description.new(EX.Subject,
               init: [
                 {EX.Subject, EX.predicate1(), EX.Object1},
                 {EX.Subject, EX.predicate1(), EX.Object2},
                 {EX.Subject, EX.predicate2(), EX.Object3}
               ]
             )[EX.predicate1()] ==
               [RDF.iri(EX.Object1), RDF.iri(EX.Object2)]
    end
  end
end
