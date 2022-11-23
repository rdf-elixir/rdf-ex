defmodule RDF.Normalization.W3C.Test do
  @moduledoc """
  The official W3C RDF 1.1 Turtles Test Suite.

  from <https://www.w3.org/2013/TurtleTests/>

  see also <https://www.w3.org/2011/rdf-wg/wiki/RDF_Test_Suites#Turtle_Tests>
  """

  use ExUnit.Case, async: false
  ExUnit.Case.register_attribute(__ENV__, :test_case)

  alias RDF.{TestSuite, NQuads, Normalization}
  alias TestSuite.NS.RDFN

  @path RDF.TestData.path("rdf-dataset-canonicalization")
  @base "https://w3c.github.io/rch-rdc/tests/"
  @manifest TestSuite.manifest_path(@path, "manifest-urdna2015.ttl")
            |> TestSuite.manifest_graph(base: @base)

  TestSuite.test_cases(@manifest, RDFN.Urdna2015EvalTest)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    unless test_case.subject ==
             RDF.iri("https://w3c.github.io/rch-rdc/tests/manifest-urdna2015#test025") do
      @tag skip: "TODO"
    end

    test TestSuite.test_title(test_case), %{test_case: test_case} do
      with base = to_string(TestSuite.test_input_file(test_case)) do
        assert TestSuite.test_input_file_path(test_case, @path)
               |> NQuads.read_file!(base: base)
               |> Normalization.normalize() ==
                 TestSuite.test_result_file_path(test_case, @path)
                 |> NQuads.read_file!()
      end
    end
  end)
end
