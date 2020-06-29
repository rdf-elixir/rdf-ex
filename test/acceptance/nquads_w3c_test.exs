defmodule RDF.NQuads.W3C.TestSuite do
  @moduledoc """
  The official W3C RDF 1.1 N-Quads Test Suite.

  from <https://www.w3.org/2013/N-QuadsTests/>
  """

  use ExUnit.Case, async: false

  @w3c_nquads_test_suite Path.join(RDF.TestData.dir(), "N-QUADS-TESTS")

  ExUnit.Case.register_attribute(__ENV__, :nq_test)

  @w3c_nquads_test_suite
  |> File.ls!()
  |> Enum.filter(fn file -> Path.extname(file) == ".nq" end)
  |> Enum.each(fn file ->
    @nq_test file: Path.join(@w3c_nquads_test_suite, file)
    if file |> String.contains?("-bad-") do
      test "Negative syntax test: #{file}", context do
        assert {:error, _} = RDF.NQuads.read_file(context.registered.nq_test[:file])
      end
    else
      test "Positive syntax test: #{file}", context do
        assert {:ok, %RDF.Dataset{}} = RDF.NQuads.read_file(context.registered.nq_test[:file])
      end
    end
  end)
end
