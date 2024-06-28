defmodule RDF.BlankNode.Generator.IncrementTest do
  use RDF.Test.Case

  import RDF, only: [bnode: 1]

  alias RDF.BlankNode.Generator.Increment

  describe "generate/1" do
    test "without prefix" do
      assert Increment.generate(%Increment{counter: 0, map: %{}}) ==
               {bnode(0), %Increment{counter: 1, map: %{}}}
    end

    test "with prefix" do
      assert Increment.generate(%Increment{counter: 0, map: %{}, prefix: "x"}) ==
               {bnode("x0"), %Increment{counter: 1, map: %{}, prefix: "x"}}
    end
  end

  describe "generate_for/2" do
    test "when the given string not exists in the map" do
      assert Increment.generate_for(%Increment{counter: 1, map: %{"foo" => 0}}, "bar") ==
               {bnode(1), %Increment{counter: 2, map: %{"foo" => 0, "bar" => 1}}}
    end

    test "when the given string exists in the map" do
      assert Increment.generate_for(%Increment{counter: 1, map: %{"foo" => 0}}, "foo") ==
               {bnode(0), %Increment{counter: 1, map: %{"foo" => 0}}}
    end

    test "with prefix" do
      assert Increment.generate_for(
               %Increment{counter: 1, map: %{"foo" => 0}, prefix: "x"},
               "bar"
             ) ==
               {bnode("x1"), %Increment{counter: 2, map: %{"foo" => 0, "bar" => 1}, prefix: "x"}}

      assert Increment.generate_for(
               %Increment{counter: 1, map: %{"foo" => 0}, prefix: "x"},
               "foo"
             ) ==
               {bnode("x0"), %Increment{counter: 1, map: %{"foo" => 0}, prefix: "x"}}
    end
  end
end
