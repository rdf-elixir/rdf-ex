defmodule RDF.Star.NTriples.EncoderTest do
  use RDF.Test.Case

  alias RDF.NTriples

  test "annotations of triples on subject position" do
    assert NTriples.Encoder.encode!(graph_with_annotation()) ==
             """
             << <http://example.com/S> <http://example.com/P> "Foo" >> <http://example.com/ap> <http://example.com/ao> .
             """
  end

  test "annotations of triples on object position" do
        assert NTriples.Encoder.encode!(
                 Graph.new([
                   statement(),
                   {EX.AS, EX.ap(), statement()},
                 ])
               ) ==
                 """
                 <http://example.com/AS> <http://example.com/ap> << <http://example.com/S> <http://example.com/P> "Foo" >> .
                 <http://example.com/S> <http://example.com/P> "Foo" .
                 """
  end
end
