defmodule RDF.Sigils do

  @doc ~S"""
  Handles the sigil `~I` for IRIs.

  Note: The given IRI string is precompiled into an IRI struct.

  ## Examples

      iex> import RDF.Sigils
      iex> ~I<http://example.com>
      RDF.uri("http://example.com")

  """
  defmacro sigil_I({:<<>>, _, [iri]}, []) when is_binary(iri) do
    Macro.escape(RDF.uri(iri))
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
    Macro.escape(RDF.Literal.new(value))
  end

  defmacro sigil_L({:<<>>, _, [value]}, language) when is_binary(value) do
    Macro.escape(RDF.Literal.new(value, %{language: to_string(language)}))
  end
end
