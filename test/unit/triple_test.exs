defmodule RDF.TripleTest do
  use RDF.Test.Case

  doctest RDF.Triple

  alias RDF.Triple

  describe "values/1" do
    test "with a valid RDF.Triple" do
      assert Triple.values({~I<http://example.com/S>, ~I<http://example.com/p>, RDF.integer(42)})
             == {"http://example.com/S", "http://example.com/p", 42}
    end

    test "with an invalid RDF.Triple" do
      refute Triple.values({~I<http://example.com/S>, ~I<http://example.com/p>})
      refute Triple.values({self(), self(), self()})
    end
  end
end
