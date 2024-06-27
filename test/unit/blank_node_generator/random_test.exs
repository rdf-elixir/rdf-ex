defmodule RDF.BlankNode.Generator.RandomTest do
  use RDF.Test.Case

  import RDF, only: [bnode: 1]

  alias RDF.BlankNode.Generator.Random

  describe "generate/1" do
    test "without prefix" do
      assert {%BlankNode{}, %{map: %{}}} = Random.generate(%{map: %{}})
    end

    test "with prefix" do
      assert {%BlankNode{value: "b" <> _}, %{map: %{}, prefix: "b"}} =
               Random.generate(%{map: %{}, prefix: "b"})
    end
  end

  describe "generate_for/2" do
    test "when the given string not exists in the map" do
      assert {%BlankNode{value: random}, %{map: %{"foo" => "42", "bar" => random}}} =
               Random.generate_for("bar", %{map: %{"foo" => "42"}})
    end

    test "when the given string exists in the map" do
      assert Random.generate_for("foo", %{map: %{"foo" => "42"}}) ==
               {bnode("42"), %{map: %{"foo" => "42"}}}
    end

    test "with prefix" do
      assert {
               %BlankNode{value: "b" <> random},
               %{map: %{"foo" => "42", "bar" => random}, prefix: "b"}
             } =
               Random.generate_for("bar", %{map: %{"foo" => "42"}, prefix: "b"})

      assert Random.generate_for("foo", %{map: %{"foo" => "42"}, prefix: "b"}) ==
               {bnode("b42"), %{map: %{"foo" => "42"}, prefix: "b"}}
    end
  end
end
