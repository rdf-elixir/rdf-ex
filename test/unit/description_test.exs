defmodule RDF.DescriptionTest do
  use ExUnit.Case

  defmodule EX, do:
    use RDF.Vocabulary, base_uri: "http://example.com/description/"

  doctest RDF.Description

  alias RDF.Description
  import RDF, only: [uri: 1, literal: 1, bnode: 1]


  def description, do: Description.new(EX.Subject)
  def description_of_subject(%Description{subject: subject}, subject), do: true
  def description_of_subject(_, _), do: false
  def empty_description(%Description{predications: predications}) do
    predications == %{}
  end
  def description_includes_predication(desc, {predicate, object}) do
    desc.predications
    |> Map.get(predicate, %{})
    |> Enum.member?({object, nil})
  end

  describe "creating an empty description" do
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
  end

  test "creating a description with a single initial triple" do
    desc = Description.new({EX.Subject, EX.predicate, EX.Object})
    assert description_of_subject(desc, uri(EX.Subject))
    assert description_includes_predication(desc, {EX.predicate, uri(EX.Object)})

    desc = Description.new({EX.Subject, EX.predicate, 42})
    assert description_of_subject(desc, uri(EX.Subject))
    assert description_includes_predication(desc, {EX.predicate, literal(42)})
  end

  test "creating a description with a list of initial triples" do
    desc = Description.new([{EX.Subject, EX.predicate1, EX.Object1},
                            {EX.Subject, EX.predicate2, EX.Object2}])
    assert description_of_subject(desc, uri(EX.Subject))
    assert description_includes_predication(desc, {EX.predicate1, uri(EX.Object1)})
    assert description_includes_predication(desc, {EX.predicate2, uri(EX.Object2)})
  end

  describe "adding triples" do
    test "a predicate-object-pair of proper RDF terms" do
      assert Description.add(description, {EX.predicate, uri(EX.Object)})
        |> description_includes_predication({EX.predicate, uri(EX.Object)})
    end

    test "a predicate-object-pair of convertible RDF terms" do
      assert Description.add(description,
              {"http://example.com/description/predicate", uri(EX.Object)})
        |> description_includes_predication({EX.predicate, uri(EX.Object)})

      assert Description.add(description,
              {"http://example.com/description/predicate", 42})
        |> description_includes_predication({EX.predicate, literal(42)})

      # TODO: Test a url-string as object ...

      assert Description.add(description,
              {"http://example.com/description/predicate", bnode(:foo)})
        |> description_includes_predication({EX.predicate, bnode(:foo)})
    end

    test "a proper triple" do
      assert Description.add(description,
                {uri(EX.Subject), EX.predicate, uri(EX.Object)})
        |> description_includes_predication({EX.predicate, uri(EX.Object)})

      assert Description.add(description,
                {uri(EX.Subject), EX.predicate, literal(42)})
        |> description_includes_predication({EX.predicate, literal(42)})

      assert Description.add(description,
                {uri(EX.Subject), EX.predicate, bnode(:foo)})
        |> description_includes_predication({EX.predicate, bnode(:foo)})
    end

    test "add ignores triples not about the subject of the Description struct" do
      assert empty_description(
        Description.add(description, {EX.Other, EX.predicate, uri(EX.Object)}))
    end

    test "a list of predicate-object-pairs" do
      desc = Description.add(description,
        [{EX.predicate, EX.Object1}, {EX.predicate, EX.Object2}])
      assert description_includes_predication(desc, {EX.predicate, uri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate, uri(EX.Object2)})
    end

    test "a list of triples" do
      desc = Description.add(description, [
        {EX.Subject, EX.predicate1, EX.Object1},
        {EX.Subject, EX.predicate2, EX.Object2}
      ])
      assert description_includes_predication(desc, {EX.predicate1, uri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate2, uri(EX.Object2)})
    end

    test "a list of mixed triples and predicate-object-pairs" do
      desc = Description.add(description, [
        {EX.predicate, EX.Object1},
        {EX.Subject, EX.predicate, EX.Object2},
        {EX.Other,   EX.predicate, EX.Object3}
      ])
      assert description_of_subject(desc, uri(EX.Subject))
      assert description_includes_predication(desc, {EX.predicate, uri(EX.Object1)})
      assert description_includes_predication(desc, {EX.predicate, uri(EX.Object2)})
      refute description_includes_predication(desc, {EX.predicate, uri(EX.Object3)})
    end

    test "duplicates are ignored" do
      desc = Description.add(description, {EX.predicate, EX.Object})
      assert Description.add(desc, {EX.predicate, EX.Object}) == desc
      assert Description.add(desc, {EX.Subject, EX.predicate, EX.Object}) == desc

      desc = Description.add(description, {EX.predicate, 42})
      assert Description.add(desc, {EX.predicate, literal(42)}) == desc
    end

    test "non-convertible Triple elements are causing an error" do
      assert_raise RDF.InvalidURIError, fn ->
        Description.add(description, {"not a URI", uri(EX.Object)})
      end

      assert_raise RDF.InvalidLiteralError, fn ->
        Description.add(description, {EX.prop, self})
      end
    end
  end

  test "pop a triple" do
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

  describe "Enumerable implementation" do
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
      assert desc == Enum.reduce(desc, description,
        fn(triple, acc) -> acc |> Description.add(triple) end)
    end
  end

end
