defmodule RDF.Star.Turtle.W3C.EvalTest do
  @moduledoc """
  The official W3C RDF 1.2 Turtle Eval Test Suite.

  See <https://w3c.github.io/rdf-tests/rdf/rdf12/rdf-turtle/>.
  """

  use ExUnit.Case, async: false
  use RDF.Test.EarlFormatter, test_suite: :turtle_star

  alias RDF.{Turtle, TestSuite, NTriples}
  alias TestSuite.NS.RDFT

  @path RDF.TestData.path("rdf-tests/rdf12/rdf-turtle/eval")
  @base "https://w3c.github.io/rdf-tests/rdf/rdf12/rdf-turtle/eval/"
  @manifest TestSuite.manifest_path(@path) |> TestSuite.manifest_graph(base: @base)

  TestSuite.test_cases(@manifest, RDFT.TestTurtleEval)
  |> Enum.each(fn test_case ->
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
           TODO: Wait until RDF-star-support for the RDF dataset canonicalization (used for our
           graph isomorphism algorithm) is specified and implemented.
           See this issue: https://github.com/w3c/rdf-canon/issues/2
           """
    end

    @tag test_case: test_case
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
