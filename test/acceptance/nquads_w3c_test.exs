defmodule RDF.NQuads.W3C.TestSuite do
  @moduledoc """
  The official W3C RDF 1.1 N-Quads Test Suite.

  from <https://www.w3.org/2013/N-QuadsTests/>
  """

  use ExUnit.Case, async: false

  alias RDF.{TestSuite, NQuads}
  alias TestSuite.NS.RDFT

  @path RDF.TestData.path("N-QUADS-TESTS")
  @base "http://example/base/"
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
