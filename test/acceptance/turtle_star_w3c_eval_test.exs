defmodule RDF.Star.Turtle.W3C.EvalTest do
  @moduledoc """
  The official RDF-star Turtle eval test suite.

  from <https://w3c.github.io/rdf-star/tests/turtle/eval/>
  """

  use ExUnit.Case, async: false

  @turtle_star_eval_test_suite Path.join(RDF.TestData.dir(), "rdf-star/turtle/eval")

  ExUnit.Case.register_attribute(__ENV__, :turtle_test)

  @turtle_star_eval_test_suite
  |> File.ls!()
  |> Enum.filter(fn file -> Path.extname(file) == ".ttl" and file != "manifest.ttl" end)
  |> Enum.each(fn file ->
    base = Path.basename(file, ".ttl")

    if base in [
         "turtle-star-eval-bnode-1",
         "turtle-star-eval-bnode-2",
         # TODO: this one just fails, because our blank node counter starts at 0 instead of 1
         "turtle-star-eval-annotation-2"
       ] do
      @tag skip: """
           The produced graphs are correct, but have different blank node labels than the result graph.
           TODO: Implement a graph isomorphism algorithm.
           """
    end

    @turtle_test ttl_file: Path.join(@turtle_star_eval_test_suite, file),
                 nt_file: Path.join(@turtle_star_eval_test_suite, base <> ".nt")
    test "eval test: #{file}", context do
      assert RDF.Turtle.read_file!(context.registered.turtle_test[:ttl_file])
             |> RDF.Graph.clear_metadata() ==
               RDF.NTriples.read_file!(context.registered.turtle_test[:nt_file])
    end
  end)
end
