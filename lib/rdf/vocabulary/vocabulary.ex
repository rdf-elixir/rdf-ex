defmodule RDF.Vocabulary do
  @moduledoc !"Various functions for working RDF vocabularies and their URIs."

  alias RDF.IRI

  @path "priv/vocabs"
  def path, do: @path

  def extract_terms(data, base_iri) do
    data
    |> RDF.Data.resources()
    |> Stream.filter(&match?(%IRI{}, &1))
    |> Stream.map(&to_string/1)
    |> Stream.map(&strip_base_iri(&1, base_iri))
    |> Stream.filter(&vocab_term?/1)
    |> Enum.map(&String.to_atom/1)
  end

  defp strip_base_iri(iri, base_iri) do
    if String.starts_with?(iri, base_iri) do
      String.replace_prefix(iri, base_iri, "")
    end
  end

  defp vocab_term?(""), do: false
  defp vocab_term?(term) when is_binary(term), do: not String.contains?(term, "/")
  defp vocab_term?(_), do: false

  @doc false
  @spec term_to_iri(String.t(), String.t() | atom) :: IRI.t()
  def term_to_iri(base_iri, term) when is_atom(term),
    do: term_to_iri(base_iri, Atom.to_string(term))

  def term_to_iri(base_iri, term), do: RDF.iri(base_iri <> term)
end
