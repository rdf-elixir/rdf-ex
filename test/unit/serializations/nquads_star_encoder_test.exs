defmodule RDF.Star.NQuads.EncoderTest do
  use RDF.Test.Case

  alias RDF.NQuads

  test "quoted triples on subject position" do
    assert NQuads.Encoder.encode!(graph_with_annotation()) ==
             """
             << <http://example.com/S> <http://example.com/P> "Foo" >> <http://example.com/ap> <http://example.com/ao> .
             """

    assert graph_with_annotation()
           |> Graph.change_name(EX.Graph)
           |> Dataset.new()
           |> NQuads.Encoder.encode!() ==
             """
             << <http://example.com/S> <http://example.com/P> "Foo" >> <http://example.com/ap> <http://example.com/ao> <http://example.com/Graph> .
             """
  end

  test "quoted triples on object position" do
    assert Graph.new([
             statement(),
             {EX.AS, EX.ap(), statement()}
           ])
           |> NQuads.Encoder.encode!() ==
             """
             <http://example.com/AS> <http://example.com/ap> << <http://example.com/S> <http://example.com/P> "Foo" >> .
             <http://example.com/S> <http://example.com/P> "Foo" .
             """

    assert Graph.new(
             [
               statement(),
               {EX.AS, EX.ap(), statement()}
             ],
             name: EX.Graph
           )
           |> Dataset.new()
           |> NQuads.Encoder.encode!() ==
             """
             <http://example.com/AS> <http://example.com/ap> << <http://example.com/S> <http://example.com/P> "Foo" >> <http://example.com/Graph> .
             <http://example.com/S> <http://example.com/P> "Foo" <http://example.com/Graph> .
             """
  end

  test "nested quoted triples" do
    assert Graph.new([
             {
               {{EX.s1(), EX.p1(), EX.o1()}, EX.q1(), {EX.s2(), EX.p2(), EX.o2()}},
               EX.q2(),
               {{EX.s3(), EX.p3(), EX.o3()}, EX.q3(), {EX.s4(), EX.p4(), EX.o4()}}
             }
           ])
           |> NQuads.Encoder.encode!() ==
             """
             << << <http://example.com/s1> <http://example.com/p1> <http://example.com/o1> >> <http://example.com/q1> << <http://example.com/s2> <http://example.com/p2> <http://example.com/o2> >> >> <http://example.com/q2> << << <http://example.com/s3> <http://example.com/p3> <http://example.com/o3> >> <http://example.com/q3> << <http://example.com/s4> <http://example.com/p4> <http://example.com/o4> >> >> .
             """

    assert Graph.new(
             [
               {
                 {{EX.s1(), EX.p1(), EX.o1()}, EX.q1(), {EX.s2(), EX.p2(), EX.o2()}},
                 EX.q2(),
                 {{EX.s3(), EX.p3(), EX.o3()}, EX.q3(), {EX.s4(), EX.p4(), EX.o4()}}
               }
             ],
             name: EX.Graph
           )
           |> Dataset.new()
           |> NQuads.Encoder.encode!() ==
             """
             << << <http://example.com/s1> <http://example.com/p1> <http://example.com/o1> >> <http://example.com/q1> << <http://example.com/s2> <http://example.com/p2> <http://example.com/o2> >> >> <http://example.com/q2> << << <http://example.com/s3> <http://example.com/p3> <http://example.com/o3> >> <http://example.com/q3> << <http://example.com/s4> <http://example.com/p4> <http://example.com/o4> >> >> <http://example.com/Graph> .
             """
  end
end
