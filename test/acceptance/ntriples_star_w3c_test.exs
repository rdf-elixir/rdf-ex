defmodule RDF.Star.NTriples.W3C.TestSuite do
  @moduledoc """
  The official RDF-star N-Triples Test Suite.

  from <https://w3c.github.io/rdf-star/tests/nt/syntax/>
  """

  use ExUnit.Case, async: false
  use RDF.Test.EarlFormatter, test_suite: :ntriples_star

  alias RDF.{TestSuite, NTriples}
  alias TestSuite.NS.RDFT

  @path RDF.TestData.path("rdf-star/nt/syntax")
  @base "http://example/base/"
  @manifest TestSuite.manifest_path(@path) |> TestSuite.manifest_graph(base: @base)

  @manifest
  |> TestSuite.test_cases(RDFT.TestNTriplesPositiveSyntax)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      assert {:ok, %RDF.Graph{}} =
               test_case
               |> TestSuite.test_input_file_path(@path)
               |> NTriples.read_file()
    end
  end)

  @manifest
  |> TestSuite.test_cases(RDFT.TestNTriplesNegativeSyntax)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      assert {:error, _} =
               test_case
               |> TestSuite.test_input_file_path(@path)
               |> NTriples.read_file()
    end
  end)
end
