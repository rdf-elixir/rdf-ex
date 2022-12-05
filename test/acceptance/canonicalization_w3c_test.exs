defmodule RDF.Canonicalization.W3C.Test do
  @moduledoc """
  The RDF Dataset Canonicalization Test Suite.

  from <https://github.com/w3c-ccg/rdf-dataset-canonicalization/>
  """

  use ExUnit.Case, async: false
  ExUnit.Case.register_attribute(__ENV__, :test_case)

  alias RDF.{TestSuite, NQuads, Canonicalization}
  alias TestSuite.NS.RDFN

  @path RDF.TestData.path("rdf-dataset-canonicalization")
  @base "https://w3c.github.io/rch-rdc/tests/"
  @manifest TestSuite.manifest_path(@path, "manifest-urdna2015.ttl")
            |> TestSuite.manifest_graph(base: @base)

  TestSuite.test_cases(@manifest, RDFN.Urdna2015EvalTest)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      base = to_string(TestSuite.test_input_file(test_case))

      assert TestSuite.test_input_file_path(test_case, @path)
             |> NQuads.read_file!(base: base)
             |> Canonicalization.canonicalize() ==
               TestSuite.test_result_file_path(test_case, @path)
               |> NQuads.read_file!()
    end
  end)
end
