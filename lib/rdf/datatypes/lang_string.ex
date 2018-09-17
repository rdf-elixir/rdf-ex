defmodule RDF.LangString do
  @moduledoc """
  `RDF.Datatype` for RDF langString.
  """

  use RDF.Datatype, id: RDF.uri("http://www.w3.org/1999/02/22-rdf-syntax-ns#langString")


  def build_literal(value, lexical, %{language: language} = opts)
      when is_binary(language) and language != "" do
    %Literal{super(value, lexical, opts) | language: String.downcase(language)}
  end

  def build_literal(value, lexical, opts) do
    super(value, lexical, opts)
  end


  @impl RDF.Datatype
  def convert(value, _), do: to_string(value)


  @impl RDF.Datatype
  def valid?(literal)
  def valid?(%Literal{language: nil}), do: false
  def valid?(literal), do: super(literal)


  @impl RDF.Datatype
  def cast(_) do
    nil
  end


  @doc """
  Checks if a language tagged string literal or language tag matches a language range.

  The check is performed per the basic filtering scheme defined in
  [RFC4647](http://www.ietf.org/rfc/rfc4647.txt) section 3.3.1.
  A language range is a basic language range per _Matching of Language Tags_ in
  RFC4647 section 2.1.
  A language range of `"*"` matches any non-empty language-tag string.

  see <https://www.w3.org/TR/sparql11-query/#func-langMatches>
  """
  def match_language?(language_tag, language_range)

  def match_language?(%Literal{language: nil}, _), do: false
  def match_language?(%Literal{language: language_tag}, language_range),
    do: match_language?(language_tag, language_range)

  def match_language?("", "*"), do: false
  def match_language?(_, "*"),  do: true

  def match_language?(language_tag, language_range) do
    language_tag = String.downcase(language_tag)
    language_range = String.downcase(language_range)

    case String.split(language_tag, language_range, parts: 2) do
      [_, rest] -> rest == "" or String.starts_with?(rest, "-")
      _         -> false
    end
  end

end
