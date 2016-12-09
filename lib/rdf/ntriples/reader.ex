defmodule RDF.NTriples.Reader do
  @moduledoc """
  `RDF::NTriples` provides support for reading the N-Triples serialization
  format.

  N-Triples is a line-based plain-text format for encoding an RDF graph.
  It is a very restricted, explicit and well-defined subset of both
  [Turtle](http://www.w3.org/TeamSubmission/turtle/) and
  [Notation3](http://www.w3.org/TeamSubmission/n3/) (N3).

  The MIME content type for N-Triples files is `text/plain` and the
  recommended file extension is `.nt`.

  An example of an RDF statement in N-Triples format:

      <https://hex.pm/> <http://purl.org/dc/terms/title> "Hex" .
  """

  use RDF.Reader

  def read_string(content, _opts \\ []) do
    with {:ok, tokens, _} <- tokenize(content),
         {:ok, ast}       <- parse(tokens) do
      {:ok, build_graph(ast)}
    else
      {:error, {error_line, :ntriples_lexer, error_descriptor}, _error_line_again} ->
        {:error, "N-Triple scanner error on line #{error_line}: #{inspect error_descriptor}"}
      {:error, {error_line, :ntriples_parser, error_descriptor}} ->
        {:error, "N-Triple parser error on line #{error_line}: #{inspect error_descriptor}"}
    end
  end

  defp tokenize(content), do: content |> to_charlist |> :ntriples_lexer.string

  defp parse(tokens), do: tokens |> :ntriples_parser.parse

  defp build_graph(ast) do
    Enum.reduce ast, RDF.Graph.new, fn(triple, graph) ->
      RDF.Graph.add(graph, triple)
    end
  end

end
