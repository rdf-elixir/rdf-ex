defmodule RDF.Star.Turtle.W3C.EvalTest do
  @moduledoc """
  The official RDF-star Turtle eval test suite.

  from <https://w3c.github.io/rdf-star/tests/turtle/eval/>
  """

  use ExUnit.Case, async: false
  use EarlFormatter, test_suite: :turtle_star

  alias RDF.{Turtle, TestSuite, NTriples}
  alias TestSuite.NS.RDFT

  @path RDF.TestData.path("rdf-star/turtle/eval")
  @base "http://example/base/"
  @manifest TestSuite.manifest_path(@path) |> TestSuite.manifest_graph(base: @base)

  TestSuite.test_cases(@manifest, RDFT.TestTurtleEval)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case

    if (test_case |> TestSuite.test_input_file_path(@path) |> Path.basename(".ttl")) in [
         "turtle-star-eval-bnode-1",
         "turtle-star-eval-bnode-2",
         # TODO: this one just fails, because our blank node counter starts at 0 instead of 1
         "turtle-star-eval-annotation-2"
       ] do
      @tag earl_result: :passed
      @tag earl_mode: :semi_auto
      @tag skip: """
           The produced graphs are correct, but have different blank node labels than the result graph.
           TODO: Implement a graph isomorphism algorithm.
           """
    end

    test TestSuite.test_title(test_case), %{test_case: test_case} do
      assert RDF.Graph.equal?(
               TestSuite.test_input_file_path(test_case, @path)
               |> Turtle.read_file!()
               |> RDF.Graph.clear_metadata(),
               TestSuite.test_result_file_path(test_case, @path)
               |> NTriples.read_file!()
             )
    end
  end)
end
