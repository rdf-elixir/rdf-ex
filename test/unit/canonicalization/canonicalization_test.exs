defmodule RDF.CanonicalizationTest do
  use RDF.Test.Case

  doctest RDF.Canonicalization

  describe "canonicalize/1" do
    test "the canonicalization of a RDF.Graph is equal to this RDF.Graph in a canonicalized RDF.Dataset" do
      graph =
        Graph.build do
          ~B<foo> |> EX.p(~B<bar>)
          ~B<bar> |> EX.p(42)
        end

      assert %Graph{} = canonicalized_graph = Graph.canonicalize(graph)
      assert Dataset.canonicalize(graph) == Dataset.new(canonicalized_graph)
    end
  end
end
