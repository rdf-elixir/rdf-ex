defmodule RDF.BlankNodeTest do
  use RDF.Test.Case

  doctest RDF.BlankNode

  alias RDF.BlankNode

  describe "new/1" do
    test "with a string" do
      assert BlankNode.new("foo") == %BlankNode{value: "foo"}
    end

    test "with an atom" do
      assert BlankNode.new(:foo) == %BlankNode{value: "foo"}
    end

    test "with a integer" do
      assert BlankNode.new(42) == %BlankNode{value: "42"}
    end

    test "with a ref" do
      assert %BlankNode{value: value} = BlankNode.new(make_ref())
      assert is_binary(value)
    end
  end
end
