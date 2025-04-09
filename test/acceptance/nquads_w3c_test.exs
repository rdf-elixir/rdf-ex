defmodule RDF.NQuads.W3C.TestSuite do
  @moduledoc """
  The official W3C RDF 1.1 N-Quads Test Suite.

  See <https://w3c.github.io/rdf-tests/rdf/rdf11/rdf-n-quads/>.
  """

  use ExUnit.Case, async: false
  use RDF.Test.EarlFormatter, test_suite: :nquads_star

  alias RDF.{TestSuite, NQuads}
  alias TestSuite.NS.RDFT

  @path RDF.TestData.path("rdf-tests/rdf11/rdf-n-quads")
  @base "https://w3c.github.io/rdf-tests/rdf/rdf11/rdf-n-quads/"
  @manifest TestSuite.manifest_path(@path) |> TestSuite.manifest_graph(base: @base)

  @manifest
  |> TestSuite.test_cases(RDFT.TestNQuadsPositiveSyntax)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      assert {:ok, %RDF.Dataset{}} =
               test_case
               |> TestSuite.test_input_file_path(@path)
               |> NQuads.read_file()
    end
  end)

  @manifest
  |> TestSuite.test_cases(RDFT.TestNQuadsNegativeSyntax)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      assert {:error, _} =
               test_case
               |> TestSuite.test_input_file_path(@path)
               |> NQuads.read_file()
    end
  end)
end
