defmodule RDF.NTriples.W3C.TestSuite do
  @moduledoc """
  The official W3C RDF 1.1 N-Triples Test Suite.

  See <https://w3c.github.io/rdf-tests/rdf/rdf11/rdf-n-triples/>.
  """

  use ExUnit.Case, async: false
  use RDF.EarlFormatter, test_suite: :ntriples

  alias RDF.{TestSuite, NTriples}
  alias TestSuite.NS.RDFT

  @path RDF.TestData.path("rdf-tests/rdf11/rdf-n-triples")
  @base "https://w3c.github.io/rdf-tests/rdf/rdf11/rdf-n-triples/"
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
