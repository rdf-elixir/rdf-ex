defmodule RDF.Star.NTriples.DecoderTest do
  use RDF.Test.Case

  alias RDF.NTriples

  test "nested quoted triples" do
    assert NTriples.Decoder.decode!("""
           << << <http://example.com/s1> <http://example.com/p1> <http://example.com/o1> >> <http://example.com/q1> << <http://example.com/s2> <http://example.com/p2> <http://example.com/o2> >> >> <http://example.com/q2> << << <http://example.com/s3> <http://example.com/p3> <http://example.com/o3> >> <http://example.com/q3> << <http://example.com/s4> <http://example.com/p4> <http://example.com/o4> >> >> .
           """) ==
             Graph.new([
               {
                 {{EX.s1(), EX.p1(), EX.o1()}, EX.q1(), {EX.s2(), EX.p2(), EX.o2()}},
                 EX.q2(),
                 {{EX.s3(), EX.p3(), EX.o3()}, EX.q3(), {EX.s4(), EX.p4(), EX.o4()}}
               }
             ])
  end
end
