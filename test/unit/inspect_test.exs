defmodule RDF.InspectTest do
  use RDF.Test.Case

  alias RDF.Turtle
  alias RDF.NS.RDFS

  @test_description EX.S
                    |> RDF.type(RDFS.Class)
                    |> EX.p("foo", 42)

  @test_graph Graph.new(
                [
                  EX.S1
                  |> EX.p1(EX.O1)
                  |> EX.p2("foo", 42),
                  EX.S2
                  |> EX.p3(EX.O3)
                ],
                prefixes: [ex: EX]
              )

  describe "RDF.Description" do
    test "it includes a header" do
      {header, _} = inspect_parts(@test_description)
      assert header == "#RDF.Description"
    end

    test "it encodes the description in Turtle" do
      {_, body} = inspect_parts(@test_description)

      assert body ==
               Turtle.write_string!(@test_description, only: :triples) |> String.trim()
    end

    test ":limit option" do
      {_, triples} = inspect_parts(@test_description, limit: 2)

      assert triples ==
               (EX.S
                |> EX.p("foo", 42)
                |> Turtle.write_string!(only: :triples)
                |> String.trim()) <>
                 "..\n..."
    end
  end

  describe "RDF.Graph" do
    test "it includes a header with the graph name" do
      {header, _} = inspect_parts(@test_graph)
      assert header == "#RDF.Graph name: nil"

      graph_name = RDF.iri(EX.Graph)
      {header, _} = @test_graph |> Graph.change_name(graph_name) |> inspect_parts()
      assert header == "#RDF.Graph name: #{inspect(graph_name)}"
    end

    test "it encodes the graph in Turtle" do
      {_, body} = inspect_parts(@test_graph)
      assert body == Turtle.write_string!(@test_graph) |> String.trim()
    end

    test ":limit option" do
      {_, body} = inspect_parts(@test_graph, limit: 2)

      assert body ==
               (Graph.new(
                  EX.S1
                  |> EX.p1(EX.O1)
                  |> EX.p2(42),
                  prefixes: [ex: EX]
                )
                |> Turtle.write_string!()
                |> String.trim()) <>
                 "..\n..."
    end
  end

  def inspect_parts(graph, opts \\ []) do
    inspect_form = inspect(graph, opts)
    [header, body] = String.split(inspect_form, "\n", parts: 2)
    {header, body}
  end
end
