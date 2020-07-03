defmodule RDF.NQuads.Decoder do
  @moduledoc false

  use RDF.Serialization.Decoder

  import RDF.Serialization.ParseHelper, only: [error_description: 1]

  alias RDF.{Dataset, Graph}

  @impl RDF.Serialization.Decoder
  @spec decode(String.t(), keyword | map) :: {:ok, Graph.t() | Dataset.t()} | {:error, any}
  def decode(content, _opts \\ []) do
    with {:ok, tokens, _} <- tokenize(content),
         {:ok, ast} <- parse(tokens) do
      {:ok, build_dataset(ast)}
    else
      {:error, {error_line, :ntriples_lexer, error_descriptor}, _error_line_again} ->
        {:error,
         "N-Quad scanner error on line #{error_line}: #{error_description(error_descriptor)}"}

      {:error, {error_line, :nquads_parser, error_descriptor}} ->
        {:error,
         "N-Quad parser error on line #{error_line}: #{error_description(error_descriptor)}"}
    end
  end

  defp tokenize(content), do: content |> to_charlist |> :ntriples_lexer.string()

  defp parse(tokens), do: tokens |> :nquads_parser.parse()

  defp build_dataset(ast) do
    Enum.reduce(ast, RDF.Dataset.new(), fn quad, dataset ->
      RDF.Dataset.add(dataset, quad)
    end)
  end
end
