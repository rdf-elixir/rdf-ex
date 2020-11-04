defmodule RDF.NQuads.Decoder do
  @moduledoc false

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
  @spec decode_from_stream(Enumerable.t(), keyword) :: Dataset.t()
  def decode_from_stream(stream, _opts \\ []) do
    Enum.reduce(stream, Dataset.new(), fn line, dataset ->
      case do_decode(line, false) do
        {:ok, []} -> dataset
        {:ok, [[quad]]} -> Dataset.add(dataset, quad)
        {:error, error} -> raise error
      end
    end)
  end

  defp do_decode(content, error_with_line_number) do
    with {:ok, tokens, _} <- tokenize(content) do
      parse(tokens)
    else
      {:error, {error_line, :ntriples_lexer, error_descriptor}, _error_line_again} ->
        {:error,
         "N-Quad scanner error#{if error_with_line_number, do: " on line #{error_line}"}: #{
           error_description(error_descriptor)
         }"}

      {:error, {error_line, :nquads_parser, error_descriptor}} ->
        {:error,
         "N-Quad parser error#{if error_with_line_number, do: " on line #{error_line}"}: #{
           error_description(error_descriptor)
         }"}
    end
  end

  defp tokenize(content), do: content |> to_charlist() |> :ntriples_lexer.string()

  defp parse(tokens), do: tokens |> :nquads_parser.parse()

  defp build_dataset([]), do: Dataset.new()

  defp build_dataset([quads]) do
    Enum.reduce(quads, Dataset.new(), &Dataset.add(&2, &1))
  end
end
