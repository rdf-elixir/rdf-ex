defmodule RDF.TriG.Decoder do
  @moduledoc """
  A decoder for TriG serializations to `RDF.Dataset`s.

  As for all decoders of `RDF.Serialization.Format`s, you normally won't use these
  functions directly, but via one of the `read_` functions on the `RDF.TriG` format
  module or the generic `RDF.Serialization` module.

  #{RDF.TurtleTriG.Decoder.shared_doc()}
  """

  use RDF.Serialization.Decoder

  import RDF.Serialization.ParseHelper, only: [error_description: 1]

  alias RDF.Dataset
  alias RDF.TurtleTriG.Decoder.AST

  @impl RDF.Serialization.Decoder
  @spec decode(String.t(), keyword) :: {:ok, Dataset.t()} | {:error, any}
  def decode(content, opts \\ []) do
    base_iri =
      Keyword.get_lazy(
        opts,
        :base_iri,
        fn -> Keyword.get_lazy(opts, :base, fn -> RDF.default_base_iri() end) end
      )

    with {:ok, tokens, _} <- tokenize(content),
         {:ok, ast} <- parse(tokens) do
      AST.build_dataset(ast, base_iri && RDF.iri(base_iri), opts)
    else
      {:error, {error_line, :turtle_trig_lexer, error_descriptor}, _error_line_again} ->
        {:error,
         "TriG scanner error on line #{error_line}: #{error_description(error_descriptor)}"}

      {:error, {error_line, :trig_parser, error_descriptor}} ->
        {:error,
         "TriG parser error on line #{error_line}: #{error_description(error_descriptor)}"}
    end
  end

  def tokenize(content), do: content |> to_charlist |> :turtle_trig_lexer.string()

  def parse([]), do: {:ok, []}
  def parse(tokens), do: tokens |> :trig_parser.parse()
end
