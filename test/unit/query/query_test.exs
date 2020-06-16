defmodule RDF.QueryTest do
  use RDF.Query.Test.Case

  doctest RDF.Query

  @example_graph """
    @prefix foaf: <http://xmlns.com/foaf/0.1/> .
    @prefix ex:   <http://example.com/> .

    ex:Outlaw
      foaf:name   "Johnny Lee Outlaw" ;
      foaf:mbox   <mailto:jlow@example.com> .

    ex:Goodguy
      foaf:name   "Peter Goodguy" ;
      foaf:mbox   <mailto:peter@example.org> ;
      foaf:friend ex:Outlaw .
    """ |> RDF.Turtle.read_string!()

  def example_graph, do: @example_graph

  @example_query [{:s?, FOAF.name, ~L"Peter Goodguy"}]

  test "execute/2" do
    assert RDF.Query.execute(RDF.Query.bgp(@example_query), @example_graph) ==
            {:ok, BGP.Stream.execute(RDF.Query.bgp(@example_query), @example_graph)}

    assert RDF.Query.execute(@example_query, @example_graph) ==
            {:ok, BGP.Stream.execute(RDF.Query.bgp(@example_query), @example_graph)}
  end

  test "execute!/2" do
    assert RDF.Query.execute!(RDF.Query.bgp(@example_query), @example_graph) ==
            BGP.Stream.execute(RDF.Query.bgp(@example_query), @example_graph)

    assert RDF.Query.execute!(@example_query, @example_graph) ==
            BGP.Stream.execute(RDF.Query.bgp(@example_query), @example_graph)
  end

  test "stream/2" do
    assert RDF.Query.stream(RDF.Query.bgp(@example_query), @example_graph) ==
            {:ok, BGP.Stream.stream(RDF.Query.bgp(@example_query), @example_graph)}

    assert RDF.Query.stream(@example_query, @example_graph) ==
            {:ok, BGP.Stream.stream(RDF.Query.bgp(@example_query), @example_graph)}
  end

  test "stream!/2" do
    assert RDF.Query.stream!(RDF.Query.bgp(@example_query), @example_graph) ==
            BGP.Stream.stream(RDF.Query.bgp(@example_query), @example_graph)

    assert RDF.Query.stream!(@example_query, @example_graph) ==
            BGP.Stream.stream(RDF.Query.bgp(@example_query), @example_graph)
  end
end
