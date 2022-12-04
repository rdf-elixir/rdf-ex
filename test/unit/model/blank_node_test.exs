defmodule RDF.BlankNodeTest do
  use RDF.Test.Case

  doctest RDF.BlankNode

  alias RDF.BlankNode

  describe "new/1" do
    test "with a string" do
      assert BlankNode.new("foo") == %BlankNode{value: "foo"}
    end

    test "with a string having the _: prefix" do
      assert BlankNode.new("_:foo") == %BlankNode{value: "foo"}
    end

    test "with an atom" do
      assert BlankNode.new(:foo) == %BlankNode{value: "foo"}
    end

    test "with a integer" do
      assert BlankNode.new(42) == %BlankNode{value: "b42"}
    end

    test "with a ref" do
      assert %BlankNode{value: value} = BlankNode.new(make_ref())
      assert is_binary(value)
    end
  end

  test "internal representation are valid Turtle blank node" do
    [
      BlankNode.new(),
      BlankNode.new("foo"),
      BlankNode.new(:foo),
      BlankNode.new(42),
      BlankNode.new(-42),
      BlankNode.new(make_ref())
    ]
    |> Enum.each(fn bnode ->
      assert {:ok, graph} =
               [
                 {EX.S1, EX.p1(), bnode},
                 {EX.S2, EX.p1(), bnode}
               ]
               |> Graph.new()
               |> RDF.Turtle.write_string!()
               |> RDF.Turtle.read_string()

      assert Graph.triple_count(graph) == 2
    end)
  end
end
