defmodule RDF.Turtle.W3C.Test do
  @moduledoc """
  The official W3C RDF 1.1 Turtles Test Suite.

  from <https://www.w3.org/2013/TurtleTests/>

  see also <https://www.w3.org/2011/rdf-wg/wiki/RDF_Test_Suites#Turtle_Tests>
  """

  use ExUnit.Case, async: false
  use RDF.EarlFormatter, test_suite: :turtle

  alias RDF.{Turtle, TestSuite, NTriples}
  alias TestSuite.NS.RDFT

  @path RDF.TestData.path("TURTLE-TESTS")
  @base "http://www.w3.org/2013/TurtleTests/"
  @manifest TestSuite.manifest_path(@path) |> TestSuite.manifest_graph(base: @base)

  TestSuite.test_cases(@manifest, RDFT.TestTurtleEval)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      base = to_string(TestSuite.test_input_file(test_case))

      assert RDF.Graph.isomorphic?(
               TestSuite.test_input_file_path(test_case, @path)
               |> Turtle.read_file!(base: base),
               TestSuite.test_result_file_path(test_case, @path)
               |> NTriples.read_file!()
             )
    end
  end)

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

  TestSuite.test_cases(@manifest, RDFT.TestTurtleNegativeEval)
  |> Enum.each(fn test_case ->
    if TestSuite.test_name(test_case) in ~w[
            turtle-eval-bad-01
            turtle-eval-bad-02
            turtle-eval-bad-03
          ] do
      @tag earl_result: :failed
      @tag skip: "TODO: IRI validation"
    end

    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      base = to_string(TestSuite.test_input_file(test_case))

      assert {:error, _} =
               TestSuite.test_input_file_path(test_case, @path)
               |> Turtle.read_file(base: base)
    end
  end)
end
