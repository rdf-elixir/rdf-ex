defmodule RDF.BlankNode.Generator.IncrementTest do
  use RDF.Test.Case

  import RDF, only: [bnode: 1]

  alias RDF.BlankNode.Generator.Increment

  describe "generate/1" do
    test "without prefix" do
      assert Increment.generate(%{counter: 0, map: %{}}) ==
               {bnode(0), %{counter: 1, map: %{}}}
    end

    test "with prefix" do
      assert Increment.generate(%{counter: 0, map: %{}, prefix: "b"}) ==
               {bnode("b0"), %{counter: 1, map: %{}, prefix: "b"}}
    end
  end

  describe "generate_for/2" do
    test "when the given string not exists in the map" do
      assert Increment.generate_for("bar", %{counter: 1, map: %{"foo" => 0}}) ==
               {bnode(1), %{counter: 2, map: %{"foo" => 0, "bar" => 1}}}
    end

    test "when the given string exists in the map" do
      assert Increment.generate_for("foo", %{counter: 1, map: %{"foo" => 0}}) ==
               {bnode(0), %{counter: 1, map: %{"foo" => 0}}}
    end

    test "with prefix" do
      assert Increment.generate_for("bar", %{counter: 1, map: %{"foo" => 0}, prefix: "b"}) ==
               {bnode("b1"), %{counter: 2, map: %{"foo" => 0, "bar" => 1}, prefix: "b"}}

      assert Increment.generate_for("foo", %{counter: 1, map: %{"foo" => 0}, prefix: "b"}) ==
               {bnode("b0"), %{counter: 1, map: %{"foo" => 0}, prefix: "b"}}
    end
  end
end
