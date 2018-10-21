defmodule RDF.QuadTest do
  use RDF.Test.Case

  doctest RDF.Quad

  alias RDF.Quad

  describe "values/1" do
    test "with a valid RDF.Quad" do
      assert Quad.values({~I<http://example.com/S>, ~I<http://example.com/p>, RDF.integer(42), ~I<http://example.com/Graph>})
             == {"http://example.com/S", "http://example.com/p", 42, "http://example.com/Graph"}
      assert Quad.values({~I<http://example.com/S>, ~I<http://example.com/p>, RDF.integer(42), nil})
             == {"http://example.com/S", "http://example.com/p", 42, nil}
    end

    test "with an invalid RDF.Quad" do
      refute Quad.values({~I<http://example.com/S>, ~I<http://example.com/p>})
      refute Quad.values({self(), self(), self(), self()})
    end
  end
end
