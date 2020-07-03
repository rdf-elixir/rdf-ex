defmodule RDF.NTriples.W3C.TestSuite do
  @moduledoc """
  The official W3C RDF 1.1 N-Triples Test Suite.

  from <https://www.w3.org/2013/N-TriplesTests/>
  """

  use ExUnit.Case, async: false

  @w3c_ntriples_test_suite Path.join(RDF.TestData.dir(), "N-TRIPLES-TESTS")

  ExUnit.Case.register_attribute(__ENV__, :nt_test)

  @w3c_ntriples_test_suite
  |> File.ls!()
  |> Enum.filter(fn file -> Path.extname(file) == ".nt" end)
  |> Enum.each(fn file ->
    @nt_test file: Path.join(@w3c_ntriples_test_suite, file)
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
