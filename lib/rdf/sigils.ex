defmodule RDF.Sigils do
  @moduledoc """
  Sigils for the most common types of RDF nodes.
  """

  alias RDF.{IRI, BlankNode}

  @doc ~S"""
  Handles the sigil `~I` for IRIs.

  It returns an `RDF.IRI` from the given string without interpolations and
  without escape characters, except for the escaping of the closing sigil
  character itself.

  ## Examples

      iex> import RDF.Sigils
      iex> ~I<http://example.com>
      RDF.iri("http://example.com")

  """
  defmacro sigil_I({:<<>>, _, [iri]}, []) when is_binary(iri) do
    Macro.escape(IRI.new!(iri))
  end

  @doc ~S"""
  Handles the sigil `~i` for IRIs.

  It returns an `RDF.IRI` from the given string as if it was a double-quoted
  string, replacing interpolations.

  Note: Since IRIs don't allow escaped characters that need escaping in Elixir strings
  (such as control characters), the only practical difference from `~I` is the
  support for interpolation.


  ## Examples

      iex> import RDF.Sigils
      iex> ~i<http://example.com/#{String.downcase("Foo")}>
      RDF.iri("http://example.com/foo")

  """
  defmacro sigil_i({:<<>>, _, [iri]}, []) when is_binary(iri) do
    Macro.escape(IRI.new!(iri))
  end

  defmacro sigil_i({:<<>>, line, pieces}, []) do
    quote do
      IRI.new!(unquote({:<<>>, line, pieces}))
    end
  end

  @doc ~S"""
  Handles the sigil `~B` for blank nodes.

  It returns an `RDF.BlankNode` from the given string without interpolations
  and without escape characters, except for the escaping of the closing sigil
  character itself.

  ## Examples

      iex> import RDF.Sigils
      iex> ~B<foo>
      RDF.bnode("foo")

  """
  defmacro sigil_B({:<<>>, _, [bnode]}, []) when is_binary(bnode) do
    Macro.escape(BlankNode.new(bnode))
  end

  @doc ~S"""
  Handles the sigil `~b` for blank nodes.

  It returns an `RDF.BlankNode` from the given string as if it was a double-quoted
  string, unescaping characters and replacing interpolations.

  ## Examples

      iex> import RDF.Sigils
      iex> ~b<foo#{String.downcase("Bar")}>
      RDF.bnode("foobar")

  """
  defmacro sigil_b({:<<>>, _, [bnode]}, []) when is_binary(bnode) do
    Macro.escape(BlankNode.new(bnode))
  end

  defmacro sigil_b({:<<>>, line, pieces}, []) do
    quote do
      BlankNode.new(unquote({:<<>>, line, unescape_tokens(pieces)}))
    end
  end

  @doc ~S"""
  Handles the sigil `~L` for plain Literals.

  It returns an `RDF.Literal` from the given string without interpolations and without escape characters, except for the escaping of the closing sigil character itself.

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

  @doc ~S"""
  Handles the sigil `~l` for blank nodes.

  It returns an `RDF.Literal` from the given string as if it was a double-quoted
  string, unescaping characters and replacing interpolations.

  ## Examples

      iex> import RDF.Sigils
      iex> ~l"foo #{String.downcase("Bar")}"
      RDF.literal("foo bar")
      iex> ~l"foo #{String.downcase("Bar")}"en
      RDF.literal("foo bar", language: "en")

  """
  defmacro sigil_l(value, language)

  defmacro sigil_l({:<<>>, _, [value]}, []) when is_binary(value) do
    Macro.escape(RDF.XSD.String.new(value))
  end

  defmacro sigil_l({:<<>>, _, [value]}, language) when is_binary(value) do
    Macro.escape(RDF.LangString.new(value, language: to_string(language)))
  end

  defmacro sigil_l({:<<>>, line, pieces}, []) do
    quote do
      RDF.XSD.String.new(unquote({:<<>>, line, unescape_tokens(pieces)}))
    end
  end

  defmacro sigil_l({:<<>>, line, pieces}, language) do
    quote do
      RDF.LangString.new(unquote({:<<>>, line, unescape_tokens(pieces)}),
        language: to_string(unquote(language))
      )
    end
  end

  defp unescape_tokens(tokens) do
    for token <- tokens do
      if is_binary(token), do: Macro.unescape_string(token), else: token
    end
  end
end
