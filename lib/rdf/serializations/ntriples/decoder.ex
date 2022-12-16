defmodule RDF.NTriples.Decoder do
  @moduledoc """
  A decoder for N-Triples serializations to `RDF.Graph`s.

  As for all decoders of `RDF.Serialization.Format`s, you normally won't use these
  functions directly, but via one of the `read_` functions on the `RDF.NTriples` format
  module or the generic `RDF.Serialization` module.
  """

  use RDF.Serialization.Decoder

  import RDF.Serialization.ParseHelper, only: [error_description: 1]

  alias RDF.Graph

  @impl RDF.Serialization.Decoder
  @spec decode(String.t(), keyword) :: {:ok, Graph.t()} | {:error, any}
  def decode(string, _opts \\ []) do
    with {:ok, ast} <- do_decode(string, true) do
      {:ok, build_graph(ast)}
    end
  end

  @impl RDF.Serialization.Decoder
  @spec decode_from_stream(Enumerable.t(), keyword) :: {:ok, Graph.t()} | {:error, any}
  def decode_from_stream(stream, _opts \\ []) do
    Enum.reduce_while(stream, {:ok, Graph.new()}, fn line, {:ok, graph} ->
      case do_decode(line, false) do
        {:ok, []} -> {:cont, {:ok, graph}}
        {:ok, [[triple]]} -> {:cont, {:ok, Graph.add(graph, triple)}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp do_decode(string, error_with_line_number) do
    with {:ok, tokens, _} <- tokenize(string),
         {:ok, ast} <- parse(tokens) do
      {:ok, ast}
    else
      {:error, {error_line, :ntriples_lexer, error_descriptor}, _error_line_again} ->
        {:error,
         "N-Triple scanner error#{if error_with_line_number, do: " on line #{error_line}"}: #{error_description(error_descriptor)}"}

      {:error, {error_line, :ntriples_parser, error_descriptor}} ->
        {:error,
         "N-Triple parser error#{if error_with_line_number, do: " on line #{error_line}"}: #{error_description(error_descriptor)}"}
    end
  end

  defp tokenize(content), do: content |> to_charlist() |> :ntriples_lexer.string()

  defp parse(tokens), do: tokens |> :ntriples_parser.parse()

  defp build_graph([]), do: Graph.new()

  defp build_graph([triples]) do
    Enum.reduce(triples, Graph.new(), &Graph.add(&2, &1))
  end
end
