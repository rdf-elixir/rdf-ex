defmodule RDF.Star.NQuads.TestSuite do
  @moduledoc """
  RDF-star N-Quads Test Suite.

  This runs the official RDF-star N-Triples Test Suite and variations of its
  test files with added graph names against the `RDF.NQuads.Decoder`.
  """

  use ExUnit.Case, async: false

  import RDF.Sigils

  @ntriples_star_test_suite_path "rdf-star/nt/syntax"
  @nquads_star_test_suite_path "rdf-star/nq/syntax"
  @ntriples_star_test_suite Path.join(RDF.TestData.dir(), @ntriples_star_test_suite_path)
  @nquads_star_test_suite Path.join(RDF.TestData.dir(), @nquads_star_test_suite_path)

  ExUnit.Case.register_attribute(__ENV__, :nt_test)
  ExUnit.Case.register_attribute(__ENV__, :nq_test)

  @ntriples_star_test_suite
  |> File.ls!()
  |> Enum.filter(fn file -> Path.extname(file) == ".nt" end)
  |> Enum.each(fn file ->
    @nt_test file: Path.join(@ntriples_star_test_suite, file)
    if file |> String.contains?("-bad-") do
      test "Negative syntax test: #{file}", context do
        assert {:error, _} = RDF.NQuads.read_file(context.registered.nt_test[:file])
      end
    else
      test "Positive syntax test: #{file}", context do
        assert {:ok, %RDF.Dataset{}} = RDF.NQuads.read_file(context.registered.nt_test[:file])
      end
    end
  end)

  @nquads_star_test_suite
  |> File.ls!()
  |> Enum.filter(fn file -> Path.extname(file) == ".nq" end)
  |> Enum.each(fn file ->
    @nq_test file: Path.join(@nquads_star_test_suite, file)
    test "Positive syntax test: #{file}", context do
      nq_test_file = context.registered.nq_test[:file]
      assert {:ok, %RDF.Dataset{} = dataset1} = RDF.NQuads.read_file(nq_test_file)

      nt_test_file =
        nq_test_file
        |> String.replace(
          @nquads_star_test_suite_path <> "/nquads-",
          @ntriples_star_test_suite_path <> "/ntriples-"
        )
        |> String.replace(~r/\.nq$/, ".nt")

      assert {:ok, %RDF.Dataset{} = dataset2} = RDF.NQuads.read_file(nt_test_file)

      assert RDF.Dataset.graph_count(dataset1) == 1
      assert RDF.Dataset.graph_count(dataset2) == 1

      assert %RDF.Graph{} = graph1 = RDF.Dataset.graph(dataset1, ~I<http://example/Graph>)
      assert %RDF.Graph{} = graph2 = RDF.Dataset.default_graph(dataset2)
      #
      assert RDF.Graph.change_name(graph1, nil) == graph2
    end
  end)
end
