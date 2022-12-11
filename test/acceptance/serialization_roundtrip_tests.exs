defmodule RDF.Serialization.RoundtripTests do
  use ExUnit.Case, async: false

  alias RDF.{TestSuite, NTriples, NQuads, Turtle}
  alias TestSuite.NS.RDFT

  @ntriples_path RDF.TestData.path("N-TRIPLES-TESTS")
  @ntriples_manifest TestSuite.manifest_path(@ntriples_path)
                     |> TestSuite.manifest_graph(base: "https://www.w3.org/2013/N-TriplesTests/")

  @nquads_path RDF.TestData.path("N-QUADS-TESTS")
  @nquads_manifest TestSuite.manifest_path(@nquads_path)
                   |> TestSuite.manifest_graph(base: "https://www.w3.org/2013/N-QuadsTests/")

  @turtle_path RDF.TestData.path("TURTLE-TESTS")
  @turtle_base "http://www.w3.org/2013/TurtleTests/"
  @turtle_manifest TestSuite.manifest_path(@turtle_path)
                   |> TestSuite.manifest_graph(base: @turtle_base)

  describe "N-Triples serialization roundtrip" do
    TestSuite.test_cases(@ntriples_manifest, RDFT.TestNTriplesPositiveSyntax)
    |> Enum.each(fn test_case ->
      @tag test_case: test_case
      test TestSuite.test_title(test_case), %{test_case: test_case} do
        path = TestSuite.test_input_file_path(test_case, @ntriples_path)

        assert {:ok, expected_graph} = NTriples.read_file(path)
        assert {:ok, encoding} = NTriples.write_string(expected_graph)
        assert RDF.Graph.isomorphic?(NTriples.read_string!(encoding), expected_graph)
      end
    end)
  end

  describe "N-Quads serialization roundtrip" do
    TestSuite.test_cases(@nquads_manifest, RDFT.TestNQuadsPositiveSyntax)
    |> Enum.each(fn test_case ->
      @tag test_case: test_case
      test TestSuite.test_title(test_case), %{test_case: test_case} do
        path = TestSuite.test_input_file_path(test_case, @nquads_path)

        assert {:ok, expected_dataset} = NQuads.read_file(path)
        assert {:ok, encoding} = NQuads.write_string(expected_dataset)
        assert RDF.Dataset.isomorphic?(NQuads.read_string!(encoding), expected_dataset)
      end
    end)
  end

  describe "Turtle serialization roundtrip" do
    (TestSuite.test_cases(@turtle_manifest, RDFT.TestTurtleEval) ++
       TestSuite.test_cases(@turtle_manifest, RDFT.TestTurtlePositiveSyntax))
    |> Enum.each(fn test_case ->
      @tag test_case: test_case
      test TestSuite.test_title(test_case), %{test_case: test_case} do
        base = to_string(TestSuite.test_input_file(test_case))
        path = TestSuite.test_input_file_path(test_case, @turtle_path)

        assert {:ok, expected_graph} = Turtle.read_file(path, base: base)
        assert {:ok, encoding} = Turtle.write_string(expected_graph)
        assert RDF.Graph.isomorphic?(Turtle.read_string!(encoding), expected_graph)
      end
    end)
  end
end
