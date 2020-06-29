defmodule RDF.Sigils do
  @moduledoc """
  Sigils for the most common types of RDF nodes.
  """

  @doc ~S"""
  Handles the sigil `~I` for IRIs.

  Note: The given IRI string is precompiled into an `RDF.IRI` struct.

  ## Examples

      iex> import RDF.Sigils
      iex> ~I<http://example.com>
      RDF.iri("http://example.com")

  """
  defmacro sigil_I({:<<>>, _, [iri]}, []) when is_binary(iri) do
    Macro.escape(RDF.iri!(iri))
  end

  @doc ~S"""
  Handles the sigil `~B` for blank nodes.

  ## Examples

      iex> import RDF.Sigils
      iex> ~B<foo>
      RDF.bnode("foo")

  """
  defmacro sigil_B({:<<>>, _, [bnode]}, []) when is_binary(bnode) do
    Macro.escape(RDF.BlankNode.new(bnode))
  end

  @doc ~S"""
  Handles the sigil `~L` for plain Literals.

  The sigil modifier can be used to specify a language tag.

  Note: Languages with subtags are not supported.

  ## Examples

      iex> import RDF.Sigils
      iex> ~L"foo"
      RDF.literal("foo")
      iex> ~L"foo"en
      RDF.literal("foo", language: "en")

  """
  defmacro sigil_L(value, language)

  defmacro sigil_L({:<<>>, _, [value]}, []) when is_binary(value) do
    Macro.escape(RDF.XSD.String.new(value))
  end

  defmacro sigil_L({:<<>>, _, [value]}, language) when is_binary(value) do
    Macro.escape(RDF.LangString.new(value, language: to_string(language)))
  end
end
