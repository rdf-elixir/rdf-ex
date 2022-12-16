defmodule RDF.NQuads.Decoder do
  @moduledoc """
  A decoder for N-Quads serializations to `RDF.Dataset`s.

  As for all decoders of `RDF.Serialization.Format`s, you normally won't use these
  functions directly, but via one of the `read_` functions on the `RDF.NQuads` format
  module or the generic `RDF.Serialization` module.
  """

  use RDF.Serialization.Decoder

  import RDF.Serialization.ParseHelper, only: [error_description: 1]

  alias RDF.Dataset

  @impl RDF.Serialization.Decoder
  @spec decode(String.t(), keyword) :: {:ok, Dataset.t()} | {:error, any}
  def decode(string, _opts \\ []) do
    with {:ok, ast} <- do_decode(string, true) do
      {:ok, build_dataset(ast)}
    end
  end

  @impl RDF.Serialization.Decoder
  @spec decode_from_stream(Enumerable.t(), keyword) :: {:ok, Dataset.t()} | {:error, any}
  def decode_from_stream(stream, _opts \\ []) do
    Enum.reduce_while(stream, {:ok, Dataset.new()}, fn line, {:ok, dataset} ->
      case do_decode(line, false) do
        {:ok, []} -> {:cont, {:ok, dataset}}
        {:ok, [[quad]]} -> {:cont, {:ok, Dataset.add(dataset, quad)}}
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
         "N-Quad scanner error#{if error_with_line_number, do: " on line #{error_line}"}: #{error_description(error_descriptor)}"}

      {:error, {error_line, :nquads_parser, error_descriptor}} ->
        {:error,
         "N-Quad parser error#{if error_with_line_number, do: " on line #{error_line}"}: #{error_description(error_descriptor)}"}
    end
  end

  defp tokenize(content), do: content |> to_charlist() |> :ntriples_lexer.string()

  defp parse(tokens), do: tokens |> :nquads_parser.parse()

  defp build_dataset([]), do: Dataset.new()

  defp build_dataset([quads]) do
    Enum.reduce(quads, Dataset.new(), &Dataset.add(&2, &1))
  end
end
