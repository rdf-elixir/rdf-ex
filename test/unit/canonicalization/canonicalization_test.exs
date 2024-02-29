defmodule RDF.CanonicalizationTest do
  use RDF.Test.Case

  doctest RDF.Canonicalization

  alias RDF.Canonicalization

  describe "canonicalize/1" do
    test "returns a tuple with the state" do
      expected_dataset =
        Dataset.new([{~B<c14n0>, EX.p(), ~B<c14n1>}, {~B<c14n1>, EX.p(), ~B<c14n0>}])

      assert {
               ^expected_dataset,
               %Canonicalization.State{
                 canonical_issuer: %Canonicalization.IdentifierIssuer{
                   identifier_prefix: "c14n",
                   issued_identifiers: %{~B<bar> => "c14n0", ~B<foo> => "c14n1"}
                 },
                 hash_algorithm: :sha256
               }
             } =
               [
                 {~B<foo>, EX.p(), ~B<bar>},
                 {~B<bar>, EX.p(), ~B<foo>}
               ]
               |> Graph.new()
               |> Canonicalization.canonicalize()
    end

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
