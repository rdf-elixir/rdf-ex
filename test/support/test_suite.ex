defmodule RDF.TestSuite do
  @moduledoc !"General helper functions for the W3C test suites."

  defmodule NS do
    @moduledoc false
    use RDF.Vocabulary.Namespace

    defvocab MF,
      base_iri: "http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#",
      terms: [],
      strict: false

    defvocab RDFT,
      base_iri: "http://www.w3.org/ns/rdftest#",
      terms: ~w[
        TestTurtleEval
        TestTurtlePositiveSyntax
        TestTurtleNegativeSyntax
        TestTurtleNegativeEval
        TestNTriplesPositiveSyntax
        TestNTriplesNegativeSyntax
        TestNQuadsPositiveSyntax
        TestNQuadsNegativeSyntax
      ],
      strict: false

    defvocab RDFN,
      base_iri: "http://json-ld.github.io/normalization/test-vocab#",
      terms: ~w[
        Urgna2012EvalTest
        Urdna2015EvalTest
      ],
      strict: false
  end

  @compile {:no_warn_undefined, RDF.TestSuite.NS.MF}
  @compile {:no_warn_undefined, RDF.TestSuite.NS.RDFT}

  alias NS.MF

  alias RDF.{Turtle, Graph, Description, IRI}

  def manifest_path(root), do: manifest_path(root, "manifest.ttl")
  def manifest_path(root, file), do: Path.join(root, file)

  def manifest_graph(path, opts \\ []) do
    Turtle.read_file!(path, opts)
  end

  def test_cases(manifest_graph, test_type) do
    manifest_graph
    |> Graph.descriptions()
    |> Enum.filter(&(RDF.iri(test_type) in Description.get(&1, RDF.type(), [])))
  end

  def test_name(test_case), do: value(test_case, MF.name())

  def test_title(test_case),
    # Unfortunately OTP < 20 doesn't support unicode characters in atoms,
    # so we can't put the description in the test name
    #    do: test_name(test_case) <> ": " <> value(test_case, RDFS.comment)
    do: test_name(test_case)

  def test_input_file(test_case),
    do: test_case |> Description.first(MF.action()) |> IRI.parse()

  def test_output_file(test_case),
    do: test_case |> Description.first(MF.result()) |> IRI.parse()

  def test_input_file_path(test_case, path),
    do: Path.join(path, test_input_file(test_case).path |> Path.basename())

  def test_result_file_path(test_case, path),
    do: Path.join(path, test_output_file(test_case).path |> Path.basename())

  defp value(description, property),
    do: Description.first(description, property) |> to_string()
end
