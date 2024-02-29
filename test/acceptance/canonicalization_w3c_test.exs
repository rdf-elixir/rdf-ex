defmodule RDF.Canonicalization.W3C.Test do
  @moduledoc """
  The RDF Dataset Canonicalization Test Suite.

  from <https://github.com/w3c/rdf-canon>
  """

  use ExUnit.Case, async: false
  use EarlFormatter, test_suite: :rdf_canon

  alias RDF.{TestSuite, NQuads, Canonicalization, BlankNode}
  alias TestSuite.NS.RDFC

  @path RDF.TestData.path("rdf-canon-tests")
  @base "https://w3c.github.io/rdf-canon/tests/"
  @manifest TestSuite.manifest_path(@path, "manifest.ttl")
            |> TestSuite.manifest_graph(base: @base)

  TestSuite.test_cases(@manifest, RDFC.RDFC10EvalTest)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      file_url = to_string(TestSuite.test_input_file(test_case))
      input = test_case_file(test_case, &TestSuite.test_input_file/1)
      result = test_case_file(test_case, &TestSuite.test_output_file/1)

      assert {canonicalized_dataset, _} =
               NQuads.read_file!(input, base: file_url)
               |> Canonicalization.canonicalize(hash_algorithm_opts(test_case))

      assert canonicalized_dataset == NQuads.read_file!(result)
    end
  end)

  TestSuite.test_cases(@manifest, RDFC.RDFC10MapTest)
  |> Enum.each(fn test_case ->
    @tag test_case: test_case
    test TestSuite.test_title(test_case), %{test_case: test_case} do
      file_url = to_string(TestSuite.test_input_file(test_case))
      input = test_case_file(test_case, &TestSuite.test_input_file/1)

      result =
        test_case
        |> test_case_file(&TestSuite.test_output_file/1)
        |> File.read!()
        |> Jason.decode!()

      assert {_, state} =
               NQuads.read_file!(input, base: file_url)
               |> Canonicalization.canonicalize(hash_algorithm_opts(test_case))

      assert Map.new(state.canonical_issuer.issued_identifiers, fn
               {id, issued} -> {BlankNode.value(id), issued}
             end) == result
    end
  end)

  defp test_case_file(test_case, file_type) do
    Path.join(
      @path,
      test_case
      |> file_type.()
      |> to_string()
      |> String.trim_leading(@base)
    )
  end

  defp hash_algorithm_opts(test_case) do
    case RDFC.hashAlgorithm(test_case) do
      nil ->
        []

      [hash_algorithm] ->
        [
          hash_algorithm:
            hash_algorithm
            |> to_string()
            |> String.downcase()
            |> String.to_atom()
        ]
    end
  end
end
