defmodule RDF.TestSuite do

  defmodule NS do
    use RDF.Vocabulary.Namespace

    defvocab MF,
      base_uri: "http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#",
      terms: [], strict: false

    defvocab RDFT,
      base_uri: "http://www.w3.org/ns/rdftest#",
      terms: ~w[
        TestTurtleEval
        TestTurtlePositiveSyntax
        TestTurtleNegativeSyntax
        TestTurtleNegativeEval
      ],
      strict: false
  end

  alias RDF.NS.RDFS
  alias NS.MF

  alias RDF.{Turtle, Graph, Description}


  def dir(format), do: Path.join(RDF.TestData.dir, String.upcase(format) <> "-TESTS")
  def file(filename, format), do: format |> dir |> Path.join(filename)
  def manifest_path(format),  do: file("manifest.ttl", format)

  def manifest_graph(format, opts \\ []) do
    format
    |> manifest_path
    |> Turtle.read_file!(opts)
  end

  def test_cases(format, test_type, opts) do
    format
    |> manifest_graph(opts)
    |> Graph.descriptions
    |> Enum.filter(fn description ->
        RDF.uri(test_type) in  Description.get(description, RDF.type, [])
       end)
  end

  def test_name(test_case), do: value(test_case, MF.name)

  def test_title(test_case),
# Unfortunately OTP < 20 doesn't support unicode characters in atoms,
# so we can't put the description in the test name
#    do: test_name(test_case) <> ": " <> value(test_case, RDFS.comment)
    do: test_name(test_case)

  def test_input_file(test_case), do: Description.first(test_case, MF.action)

  def test_input_file_path(test_case, format),
    do: test_input_file(test_case).path |> Path.basename |> file(format)

  def test_result_file_path(test_case, format),
    do: Description.first(test_case, MF.result).path |> Path.basename |> file(format)


  defp value(description, property),
    do: Description.first(description, property) |> to_string

end
