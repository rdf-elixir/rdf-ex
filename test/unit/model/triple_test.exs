defmodule RDF.TripleTest do
  use RDF.Test.Case

  doctest RDF.Triple

  alias RDF.Triple

  describe "values/1" do
    test "with a valid RDF.Triple" do
      assert Triple.values({~I<http://example.com/S>, ~I<http://example.com/p>, XSD.integer(42)}) ==
               {"http://example.com/S", "http://example.com/p", 42}
    end

    test "with an invalid RDF.Triple" do
      refute Triple.values({self(), self(), self()})
    end
  end

  describe "values/2" do
    test "with a valid RDF.Triple and RDF.PropertyMap" do
      assert Triple.values(
               {~I<http://example.com/S>, ~I<http://example.com/p>, XSD.integer(42)},
               context: PropertyMap.new(p: ~I<http://example.com/p>)
             ) ==
               {"http://example.com/S", :p, 42}

      assert Triple.values(
               {~I<http://example.com/S>, ~I<http://example.com/p>, XSD.integer(42)},
               context: [p: ~I<http://example.com/p>]
             ) ==
               {"http://example.com/S", :p, 42}

      assert Triple.values(
               {~I<http://example.com/S>, ~I<http://example.com/p>, XSD.integer(42)},
               context: []
             ) ==
               {"http://example.com/S", "http://example.com/p", 42}
    end

    test "with an invalid RDF.Triple" do
      refute Triple.values({self(), self(), self()}, context: PropertyMap.new())
    end
  end

  test "map/2" do
    assert {~I<http://example.com/S>, ~I<http://example.com/p>, XSD.integer(42)}
           |> Triple.map(fn
             {:object, object} -> object |> RDF.Term.value() |> Kernel.+(1)
             {_, term} -> term |> to_string() |> String.last()
           end) ==
             {"S", "p", 43}
  end
end
