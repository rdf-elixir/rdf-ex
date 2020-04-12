defmodule RDF.Literal do
  @moduledoc """
  RDF literals are leaf nodes of a RDF graph containing raw data, like strings and numbers.
  """

  defstruct [:literal]

  alias RDF.{IRI, LangString}
  alias RDF.Literal.{Generic, Datatype}

  import RDF.Literal.Helper.Macros

  @type t :: %__MODULE__{:literal => Datatype.literal()}

  @rdf_lang_string RDF.Utils.Bootstrapping.rdf_iri("langString")

  @doc """
  Creates a new `RDF.Literal` of the given value and tries to infer an appropriate XSD datatype.

  Note: The `RDF.literal` function is a shortcut to this function.

  The following mapping of Elixir types to XSD datatypes is applied:

  | Elixir datatype | XSD datatype   |
  | :-------------- | :------------- |
  | `string`        | `xsd:string`   |
  | `boolean`       | `xsd:boolean`  |
  | `integer`       | `xsd:integer`  |
  | `float`         | `xsd:double`   |
  | `Decimal`       | `xsd:decimal`  |
  | `Time`          | `xsd:time`     |
  | `Date`          | `xsd:date`     |
  | `DateTime`      | `xsd:dateTime` |
  | `NaiveDateTime` | `xsd:dateTime` |
  | `URI`           | `xsd:AnyURI`   |

  ## Examples

      iex> RDF.Literal.new(42)
      %RDF.Literal{literal: %XSD.Integer{value: 42}}

  """
  @spec new(t | any) :: t | nil
  def new(value)

  def new(%__MODULE__{} = literal),      do: literal
  def new(value) when is_binary(value),  do: RDF.XSD.String.new(value)
  def new(value) when is_boolean(value), do: RDF.XSD.Boolean.new(value)
  def new(value) when is_integer(value), do: RDF.XSD.Integer.new(value)
  def new(value) when is_float(value),   do: RDF.XSD.Double.new(value)
  def new(%Decimal{} = value),           do: RDF.XSD.Decimal.new(value)
  def new(%Date{} = value),              do: RDF.XSD.Date.new(value)
  def new(%Time{} = value),              do: RDF.XSD.Time.new(value)
  def new(%DateTime{} = value),          do: RDF.XSD.DateTime.new(value)
  def new(%NaiveDateTime{} = value),     do: RDF.XSD.DateTime.new(value)
  def new(%URI{} = value),               do: RDF.XSD.AnyURI.new(value)

  Enum.each(Datatype.Registry.datatypes(), fn datatype ->
    def new(%unquote(datatype.literal_type()){} = literal) do
      %__MODULE__{literal: literal}
    end
  end)

  def new(value) do
    raise RDF.Literal.InvalidError, "#{inspect value} not convertible to a RDF.Literal"
  end

  @doc """
  Creates a new `RDF.Literal` with the given datatype or language tag.
  """
  @spec new(t | any, keyword) :: t | nil
  def new(value, opts) do
    cond do
      length(opts) == 0 ->
        new(value)

      Keyword.has_key?(opts, :language) ->
        if Keyword.get(opts, :datatype, @rdf_lang_string) |> IRI.new() == @rdf_lang_string do
          LangString.new(value, opts)
        else
          raise ArgumentError, "datatype with language must be rdf:langString"
        end

      datatype = Keyword.get(opts, :datatype) ->
        case Datatype.Registry.get(datatype) do
          nil      -> Generic.new(value, opts)
          datatype -> datatype.new(value, opts)
        end

      true ->
        nil
    end
  end

  @doc """
  Creates a new `RDF.Literal`, but fails if it's not valid.

  Note: Validation is only possible if an `RDF.Datatype` with an implementation of
    `RDF.Datatype.valid?/1` exists.

  ## Examples

      iex> RDF.Literal.new("foo")
      %RDF.Literal{literal: %XSD.String{value: "foo"}}

      iex> RDF.Literal.new!("foo", datatype: RDF.NS.XSD.integer)
      ** (RDF.Literal.InvalidError) invalid RDF.Literal: %RDF.Literal{literal: %XSD.Integer{value: nil, lexical: "foo"}, valid: false}

      iex> RDF.Literal.new!("foo", datatype: RDF.langString)
      ** (RDF.Literal.InvalidError) invalid RDF.Literal: %RDF.Literal{literal: %RDF.LangString{language: nil, value: "foo"}, valid: false}

  """
  @spec new!(t | any, keyword) :: t
  def new!(value, opts \\ []) do
    literal = new(value, opts)
    if valid?(literal) do
      literal
    else
      raise RDF.Literal.InvalidError, "invalid RDF.Literal: #{inspect literal}"
    end
  end

  @doc """
  Returns if a literal is a language-tagged literal.

  see <http://www.w3.org/TR/rdf-concepts/#dfn-plain-literal>
  """
  @spec has_language?(t) :: boolean
  def has_language?(%__MODULE__{literal: %LangString{} = literal}), do: LangString.valid?(literal)
  def has_language?(%__MODULE__{} = _), do: false

  @doc """
  Returns if a literal is a datatyped literal.

  For historical reasons, this excludes `xsd:string` and `rdf:langString`.

  see <http://www.w3.org/TR/rdf-concepts/#dfn-typed-literal>
  """
  @spec has_datatype?(t) :: boolean
  def has_datatype?(literal) do
    not plain?(literal) and not has_language?(literal)
  end

  @doc """
  Returns if a literal is a simple literal.

  A simple literal has no datatype or language.

  see <http://www.w3.org/TR/sparql11-query/#simple_literal>
  """
  @spec simple?(t) :: boolean
  def simple?(%__MODULE__{literal: %XSD.String{}}), do: true
  def simple?(%__MODULE__{} = _),                    do: false


  @doc """
  Returns if a literal is a plain literal.

  A plain literal may have a language, but may not have a datatype.
  For all practical purposes, this includes `xsd:string` literals too.

  see <http://www.w3.org/TR/rdf-concepts/#dfn-plain-literal>
  """
  @spec plain?(t) :: boolean
  def plain?(%__MODULE__{literal: %XSD.String{}}), do: true
  def plain?(%__MODULE__{literal: %LangString{}}), do: true
  def plain?(%__MODULE__{} = _), do: false

  @spec typed?(t) :: boolean
  def typed?(literal), do: not plain?(literal)


  ############################################################################
  # functions delegating to the RDF.Datatype of a RDF.Literal

  @spec datatype(t) :: IRI.t()
  defdelegate_to_rdf_datatype :datatype

  @spec language(t) :: String.t() | nil
  defdelegate_to_rdf_datatype :language

  @spec value(t) :: any
  def value(%__MODULE__{literal: %datatype{} = literal}), do: datatype.value(literal)

  @spec lexical(t) :: String.t
  def lexical(%__MODULE__{literal: %datatype{} = literal}), do: datatype.lexical(literal)

  @spec canonical(t) :: t
  defdelegate_to_rdf_datatype :canonical

  @spec canonical?(t) :: boolean
  def canonical?(%__MODULE__{literal: %datatype{} = literal}), do: datatype.canonical?(literal)

  @spec valid?(t | any) :: boolean
  def valid?(%__MODULE__{literal: %datatype{} = literal}), do: datatype.valid?(literal)
  def valid?(_), do: false

  @spec equal_value?(t, t | any) :: boolean
  def equal_value?(%__MODULE__{literal: %datatype{} = left}, right) do
    Datatype.Registry.rdf_datatype(datatype).equal_value?(left, right)
  end

  def equal_value?(_, _), do: false

  @spec compare(t, t) :: Datatype.comparison_result | :indeterminate | nil
  def compare(%__MODULE__{literal: %datatype{} = left}, right) do
    Datatype.Registry.rdf_datatype(datatype).compare(left, right)
  end

  @doc """
  Checks if the first of two `RDF.Literal`s is smaller then the other.

  Returns `nil` when the given arguments are not comparable datatypes.
  """
  @spec less_than?(t, t) :: boolean | nil
  def less_than?(literal1, literal2) do
    case compare(literal1, literal2) do
      :lt -> true
      nil -> nil
      _   -> false
    end
  end

  @doc """
  Checks if the first of two `RDF.Literal`s is greater then the other.

  Returns `nil` when the given arguments are not comparable datatypes.
  """
  @spec greater_than?(t, t) :: boolean | nil
  def greater_than?(literal1, literal2) do
    case compare(literal1, literal2) do
      :gt -> true
      nil -> nil
      _   -> false
    end
  end


  @doc """
  Matches the lexical form of the given `XSD.Datatype` literal against a XPath and XQuery regular expression pattern with flags.

  The regular expression language is defined in _XQuery 1.0 and XPath 2.0 Functions and Operators_.

  see <https://www.w3.org/TR/xpath-functions/#func-matches>
  """
  @spec matches?(t | String.t, pattern :: t | String.t, flags :: t | String.t) :: boolean
  def matches?(value, pattern, flags \\ "")
  def matches?(%__MODULE__{} = literal, pattern, flags),
    do: matches?(lexical(literal), pattern, flags)
  def matches?(value, %__MODULE__{literal: %XSD.String{}} = pattern, flags),
    do: matches?(value, lexical(pattern), flags)
  def matches?(value, pattern, %__MODULE__{literal: %XSD.String{}} = flags),
    do: matches?(value, pattern, lexical(flags))
  def matches?(value, pattern, flags) when is_binary(value) and is_binary(pattern) and is_binary(flags),
    do: XSD.Utils.Regex.matches?(value, pattern, flags)

  defimpl String.Chars do
    def to_string(literal) do
      String.Chars.to_string(literal.literal)
    end
  end
end
