defmodule RDF.Star.TriG.W3C.EvalTest do
  @moduledoc """
  The official W3C RDF 1.2 TriG Eval Test Suite.

  See <https://w3c.github.io/rdf-tests/rdf/rdf12/rdf-trig/>.
  """

  use ExUnit.Case, async: false
  use RDF.EarlFormatter, test_suite: :trig_star

  alias RDF.{TriG, TestSuite, NQuads}
  alias TestSuite.NS.RDFT

  @path RDF.TestData.path("rdf-tests/rdf12/rdf-trig/eval")
  @base "https://w3c.github.io/rdf-tests/rdf/rdf12/rdf-trig/eval/"
  @manifest TestSuite.manifest_path(@path) |> TestSuite.manifest_graph(base: @base)

  TestSuite.test_cases(@manifest, RDFT.TestTrigEval)
  |> Enum.each(fn test_case ->
    if (test_case |> TestSuite.test_input_file_path(@path) |> Path.basename(".trig")) in [
         "trig-star-eval-bnode-1",
         "trig-star-eval-bnode-2",
         # TODO: this one just fails, because our blank node counter starts at 0 instead of 1
         "trig-star-eval-annotation-2"
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
      assert RDF.Dataset.equal?(
               TestSuite.test_input_file_path(test_case, @path)
               |> TriG.read_file!(),
               TestSuite.test_result_file_path(test_case, @path)
               |> NQuads.read_file!()
             )
    end
  end)
end
