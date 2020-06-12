defmodule RDF.QueryTest do
  use RDF.Query.Test.Case

  @example_graph Graph.new([
    {EX.s1, EX.p1, EX.o1},
    {EX.s1, EX.p2, EX.o2},
    {EX.s3, EX.p3, EX.o2}
  ])

  @example_query [{:s?, :p?, EX.o2}]

  test "execute/2" do
    assert RDF.Query.execute(RDF.Query.bgp(@example_query), @example_graph) ==
            BGP.Stream.execute(RDF.Query.bgp(@example_query), @example_graph)

    assert RDF.Query.execute(@example_query, @example_graph) ==
            BGP.Stream.execute(RDF.Query.bgp(@example_query), @example_graph)
  end

  test "stream/2" do
    assert RDF.Query.stream(RDF.Query.bgp(@example_query), @example_graph) ==
            BGP.Stream.stream(RDF.Query.bgp(@example_query), @example_graph)

    assert RDF.Query.stream(@example_query, @example_graph) ==
            BGP.Stream.stream(RDF.Query.bgp(@example_query), @example_graph)
  end
end
