defmodule RDF.BlankNode.Generator.RandomTest do
  use RDF.Test.Case

  import RDF, only: [bnode: 1]

  alias RDF.BlankNode.Generator.Random

  describe "generate/1" do
    test "without prefix" do
      assert {%BlankNode{}, %Random{map: %{}}} = Random.generate(%Random{map: %{}})
    end

    test "with prefix" do
      assert {%BlankNode{value: "b" <> _}, %Random{map: %{}, prefix: "b"}} =
               Random.generate(%Random{map: %{}, prefix: "b"})
    end
  end

  describe "generate_for/2" do
    test "when the given string not exists in the map" do
      assert {%BlankNode{value: "b" <> random}, %Random{map: %{"foo" => "42", "bar" => random}}} =
               Random.generate_for(%Random{map: %{"foo" => "42"}}, "bar")
    end

    test "when the given string exists in the map" do
      assert Random.generate_for(%Random{map: %{"foo" => "42"}}, "foo") ==
               {bnode("b42"), %Random{map: %{"foo" => "42"}}}
    end

    test "with prefix" do
      assert {
               %BlankNode{value: "x" <> random},
               %Random{map: %{"foo" => "42", "bar" => random}, prefix: "x"}
             } =
               Random.generate_for(%Random{map: %{"foo" => "42"}, prefix: "x"}, "bar")

      assert Random.generate_for(%Random{map: %{"foo" => "42"}, prefix: "x"}, "foo") ==
               {bnode("x42"), %Random{map: %{"foo" => "42"}, prefix: "x"}}
    end
  end
end
