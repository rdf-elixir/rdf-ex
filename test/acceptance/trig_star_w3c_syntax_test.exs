defmodule RDF.Star.TriG.W3C.SyntaxTest do
  @moduledoc """
  The official W3C RDF 1.2 TriG Syntax Test Suite.

  See <https://w3c.github.io/rdf-tests/rdf/rdf12/rdf-trig/>.
  """

  use ExUnit.Case, async: false
  use RDF.EarlFormatter, test_suite: :trig_star

  alias RDF.{TriG, TestSuite}
  alias TestSuite.NS.RDFT

  @path RDF.TestData.path("rdf-tests/rdf12/rdf-trig/syntax")
  @base "https://w3c.github.io/rdf-tests/rdf/rdf12/rdf-trig/syntax/"
  @manifest TestSuite.manifest_path(@path) |> TestSuite.manifest_graph(base: @base)

  TestSuite.test_cases(@manifest, RDFT.TestTrigPositiveSyntax)
  |> Enum.each(fn test_case ->
    if TestSuite.test_id(test_case) in ~w[
            trig-base-1
            trig-base-2
          ] do
      @tag earl_result: :failed
      @tag skip: "TODO: directional language-tagged strings with base direction"
    end

    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      base = to_string(TestSuite.test_input_file(test_case))

      assert {:ok, _} =
               TestSuite.test_input_file_path(test_case, @path)
               |> TriG.read_file(base: base)
    end
  end)

  TestSuite.test_cases(@manifest, RDFT.TestTrigNegativeSyntax)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      base = to_string(TestSuite.test_input_file(test_case))

      assert {:error, _} =
               TestSuite.test_input_file_path(test_case, @path)
               |> TriG.read_file(base: base)
    end
  end)
end
