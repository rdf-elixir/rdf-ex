defmodule RDF.LangString do
  @moduledoc """
  `RDF.Literal.Datatype` for `rdf:langString`s.
  """

  defstruct [:value, :language]

  @behaviour RDF.Literal.Datatype

  alias RDF.Literal.Datatype
  alias RDF.Literal

  @type t :: %__MODULE__{
               value: String.t,
               language: String.t
             }

  @iri RDF.Utils.Bootstrapping.rdf_iri("langString")
  @id to_string(@iri)

  @impl Datatype
  def literal_type, do: __MODULE__

  @impl Datatype
  def name, do: "langString"

  @impl Datatype
  def id, do: @id

  @spec new(any, String.t | atom | keyword) :: Literal.t
  def new(value, language_or_opts)
  def new(value, language) when is_binary(language), do: new(value, language: language)
  def new(value, language) when is_atom(language), do: new(value, language: language)
  def new(value, opts) do
    %Literal{
      literal: %__MODULE__{
        value: to_string(value),
        language: Keyword.get(opts, :language) |> normalize_language()
      }
    }
  end

  defp normalize_language(nil), do: nil
  defp normalize_language(""), do: nil
  defp normalize_language(language) when is_atom(language), do: language |> to_string() |> normalize_language()
  defp normalize_language(language), do: String.downcase(language)

  @spec new!(any, String.t | atom | keyword) :: Literal.t
  def new!(value, language_or_opts) do
    literal = new(value, language_or_opts)

    if valid?(literal) do
      literal
    else
      raise ArgumentError, "#{inspect(value)} with language #{inspect literal.literal.language} is not a valid #{inspect(__MODULE__)}"
    end
  end

  @impl Datatype
  def datatype(%Literal{literal: literal}), do: datatype(literal)
  def datatype(%__MODULE__{}), do: @iri

  @impl Datatype
  def language(%Literal{literal: literal}), do: language(literal)
  def language(%__MODULE__{} = literal), do: literal.language

  @impl Datatype
  def value(%Literal{literal: literal}), do: value(literal)
  def value(%__MODULE__{} = literal), do: literal.value

  @impl Datatype
  def lexical(%Literal{literal: literal}), do: lexical(literal)
  def lexical(%__MODULE__{} = literal), do: literal.value

  @impl Datatype
  def canonical(%Literal{literal: %__MODULE__{}} = literal), do: literal
  def canonical(%__MODULE__{} = literal), do: %Literal{literal: literal}

  @impl Datatype
  def canonical?(%Literal{literal: literal}), do: canonical?(literal)
  def canonical?(%__MODULE__{}), do: true

  @impl Datatype
  def valid?(%Literal{literal: %__MODULE__{} = literal}), do: valid?(literal)
  def valid?(%__MODULE__{language: language}) when is_binary(language), do: language != ""
  def valid?(_), do: false

  @impl Datatype
  def cast(%Literal{literal: %__MODULE__{}} = literal), do: literal
  def cast(_), do: nil

  @impl Datatype
  def equal_value?(left, %Literal{literal: right}), do: equal_value?(left, right)
  def equal_value?(%Literal{literal: left}, right), do: equal_value?(left, right)
  def equal_value?(%__MODULE__{} = left, right), do: left == right
  def equal_value?(_, _), do: false

  @impl Datatype
  def compare(left, %Literal{literal: right}), do: compare(left, right)
  def compare(%Literal{literal: left}, right), do: compare(left, right)
  def compare(%__MODULE__{language: language_tag} = literal1,
              %__MODULE__{language: language_tag} = literal2) do
    if valid?(literal1) and valid?(literal2) do
      case {canonical(literal1).literal.value, canonical(literal2).literal.value} do
        {value1, value2} when value1 < value2 -> :lt
        {value1, value2} when value1 > value2 -> :gt
        _ ->
          if equal_value?(literal1, literal2), do: :eq
      end
    end
  end

  def compare(_, _), do: nil

  @impl Datatype
  def update(literal, fun, opts \\ [])
  def update(%Literal{literal: literal}, fun, opts), do: update(literal, fun, opts)
  def update(%__MODULE__{} = literal, fun, _opts) do
    literal
    |> value()
    |> fun.()
    |> new(language: literal.language)
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
  @spec match_language?(Literal.t | t() | String.t, String.t) :: boolean
  def match_language?(language_tag, language_range)

  def match_language?(%Literal{literal: literal}, language_range),
    do: match_language?(literal, language_range)
  def match_language?(%__MODULE__{language: nil}, _), do: false
  def match_language?(%__MODULE__{language: language_tag}, language_range),
    do: match_language?(language_tag, language_range)

  def match_language?("", "*"), do: false
  def match_language?(_, "*"),  do: true

  def match_language?(language_tag, language_range)
      when is_binary(language_tag) and is_binary(language_range) do
    language_tag = String.downcase(language_tag)
    language_range = String.downcase(language_range)

    case String.split(language_tag, language_range, parts: 2) do
      [_, rest] -> rest == "" or String.starts_with?(rest, "-")
      _         -> false
    end
  end

  def match_language?(_, _), do: false

  defimpl String.Chars do
    def to_string(literal) do
      literal.value
    end
  end
end
