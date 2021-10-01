defmodule RDF.Star.Turtle.W3C.SyntaxTest do
  @moduledoc """
  The official RDF-star Turtle syntax test suite.

  from <https://w3c.github.io/rdf-star/tests/turtle/syntax/>
  """

  use ExUnit.Case, async: false

  @turtle_star_syntax_test_suite Path.join(RDF.TestData.dir(), "rdf-star/turtle/syntax")

  ExUnit.Case.register_attribute(__ENV__, :turtle_test)

  @turtle_star_syntax_test_suite
  |> File.ls!()
  |> Enum.filter(fn file -> Path.extname(file) == ".ttl" and file != "manifest.ttl" end)
  |> Enum.each(fn file ->
    @turtle_test file: Path.join(@turtle_star_syntax_test_suite, file)
    if file |> String.contains?("-bad-") do
      test "Negative syntax test: #{file}", context do
        assert {:error, _} = RDF.Turtle.read_file(context.registered.turtle_test[:file])
      end
    else
      test "Positive syntax test: #{file}", context do
        assert {:ok, %RDF.Graph{}} = RDF.Turtle.read_file(context.registered.turtle_test[:file])
      end
    end
  end)
end
