defmodule RDF.TriG.W3C.Test do
  @moduledoc """
  The official W3C RDF 1.1 TriG Test Suite.

  See <https://w3c.github.io/rdf-tests/rdf/rdf11/rdf-trig/>.
  """

  use ExUnit.Case, async: false
  use RDF.Test.EarlFormatter, test_suite: :trig
  import RDF.Test.Assertions

  alias RDF.{TriG, TestSuite, NQuads}
  alias TestSuite.NS.RDFT

  @path RDF.TestData.path("rdf-tests/rdf11/rdf-trig")
  @base "https://w3c.github.io/rdf-tests/rdf/rdf11/rdf-trig/"
  @manifest TestSuite.manifest_path(@path) |> TestSuite.manifest_graph(base: @base)

  TestSuite.test_cases(@manifest, RDFT.TestTrigEval)
  |> Enum.each(fn test_case ->
    unless Version.match?(System.version(), ">= 1.15.0") do
      if TestSuite.test_name(test_case) in ~w[
        IRI-resolution-01
        IRI-resolution-02
        IRI-resolution-07
        IRI-resolution-08
      ] do
        @tag earl_result: :failed
        @tag skip: "Elixir's URI.merge/2 function has a bug which was fixed in Elixir v1.15"
      end
    end

    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      base = to_string(TestSuite.test_input_file(test_case))

      assert_rdf_isomorphic TestSuite.test_input_file_path(test_case, @path)
                            |> TriG.read_file!(base: base),
                            TestSuite.test_result_file_path(test_case, @path)
                            |> NQuads.read_file!()
    end
  end)

  TestSuite.test_cases(@manifest, RDFT.TestTrigPositiveSyntax)
  |> Enum.each(fn test_case ->
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

  TestSuite.test_cases(@manifest, RDFT.TestTrigNegativeEval)
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
