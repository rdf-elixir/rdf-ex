defmodule RDF.Star.Turtle.W3C.SyntaxTest do
  @moduledoc """
  The official RDF-star Turtle syntax test suite.

  from <https://w3c.github.io/rdf-star/tests/turtle/syntax/>
  """

  use ExUnit.Case, async: false
  use EarlFormatter, test_suite: :turtle_star

  alias RDF.{Turtle, TestSuite}
  alias TestSuite.NS.RDFT

  @path RDF.TestData.path("rdf-star/turtle/syntax")
  @base "http://example/base/"
  @manifest TestSuite.manifest_path(@path) |> TestSuite.manifest_graph(base: @base)

  TestSuite.test_cases(@manifest, RDFT.TestTurtlePositiveSyntax)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      base = to_string(TestSuite.test_input_file(test_case))

      assert {:ok, _} =
               TestSuite.test_input_file_path(test_case, @path)
               |> Turtle.read_file(base: base)
    end
  end)

  TestSuite.test_cases(@manifest, RDFT.TestNTriplesPositiveSyntax)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      base = to_string(TestSuite.test_input_file(test_case))

      assert {:ok, _} =
               TestSuite.test_input_file_path(test_case, @path)
               |> Turtle.read_file(base: base)
    end
  end)

  TestSuite.test_cases(@manifest, RDFT.TestTurtleNegativeSyntax)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      base = to_string(TestSuite.test_input_file(test_case))

      assert {:error, _} =
               TestSuite.test_input_file_path(test_case, @path)
               |> Turtle.read_file(base: base)
    end
  end)
end
