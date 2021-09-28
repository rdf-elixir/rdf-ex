defmodule RDF.Star.NTriples.W3C.TestSuite do
  @moduledoc """
  The official RDF-star N-Triples Test Suite.

  from <https://w3c.github.io/rdf-star/tests/nt/syntax/>
  """

  use ExUnit.Case, async: false

  @ntriples_star_test_suite Path.join(RDF.TestData.dir(), "rdf-star/nt/syntax")

  ExUnit.Case.register_attribute(__ENV__, :nt_test)

  @ntriples_star_test_suite
  |> File.ls!()
  |> Enum.filter(fn file -> Path.extname(file) == ".nt" end)
  |> Enum.each(fn file ->
    @nt_test file: Path.join(@ntriples_star_test_suite, file)
    if file |> String.contains?("-bad-") do
      test "Negative syntax test: #{file}", context do
        assert {:error, _} = RDF.NTriples.read_file(context.registered.nt_test[:file])
      end
    else
      test "Positive syntax test: #{file}", context do
        assert {:ok, %RDF.Graph{}} = RDF.NTriples.read_file(context.registered.nt_test[:file])
      end
    end
  end)
end
