defmodule RDF.Literal do
  @moduledoc """
  RDF literals are leaf nodes of an RDF graph containing raw data, like strings, numbers etc.

  A literal is a struct consisting of a `literal` field holding either a `RDF.Literal.Datatype` struct
  for the respective known datatype of the literal or a `RDF.Literal.Generic` struct if the datatype
  is unknown, i.e. has no `RDF.Literal.Datatype` implementation.
  """

  defstruct [:literal]

  alias RDF.{IRI, LangString}
  alias RDF.Literal.{Generic, Datatype}

  import RDF.Guards

  @type t :: %__MODULE__{:literal => Datatype.literal()}

  @rdf_lang_string RDF.Utils.Bootstrapping.rdf_iri("langString")

  @doc """
  Creates a new `RDF.Literal` of the given value and tries to infer an appropriate XSD datatype.

  See `coerce/1` for applied mapping of Elixir types to XSD datatypes.

  Note: The `RDF.literal` function is a shortcut to this function.

  ## Examples

      iex> RDF.Literal.new(42)
      %RDF.Literal{literal: %RDF.XSD.Integer{value: 42}}

  """
  @spec new(t | any) :: t | nil
  def new(value) do
    case coerce(value) do
      nil ->
        raise RDF.Literal.InvalidError, "#{inspect(value)} not convertible to a RDF.Literal"

      literal ->
        literal
    end
  end

  @doc """
  Creates a new `RDF.Literal` with the given datatype or language tag.
  """
  @spec new(t | any, keyword) :: t | nil
  def new(value, opts) do
    cond do
      opts == [] ->
        new(value)

      Keyword.has_key?(opts, :language) ->
        if Keyword.get(opts, :datatype, @rdf_lang_string) |> IRI.new() == @rdf_lang_string do
          LangString.new(value, opts)
        else
          raise ArgumentError, "datatype with language must be rdf:langString"
        end

      datatype = Keyword.get(opts, :datatype) ->
        case Datatype.get(datatype) do
          nil -> Generic.new(value, opts)
          datatype -> datatype.new(value, opts)
        end

      true ->
        nil
    end
  end

  @doc """
  Coerces a new `RDF.Literal` from another value.

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

  When an `RDF.Literal` can not be coerced, `nil` is returned
  (as opposed to `new/1` which fails in this case).

  ## Examples

      iex> RDF.Literal.coerce(42)
      %RDF.Literal{literal: %RDF.XSD.Integer{value: 42}}

  """
  def coerce(value)

  def coerce(%__MODULE__{} = literal), do: literal

  def coerce(value) when is_binary(value), do: RDF.XSD.String.new(value)
  def coerce(value) when is_boolean(value), do: RDF.XSD.Boolean.new(value)
  def coerce(value) when is_integer(value), do: RDF.XSD.Integer.new(value)
  def coerce(value) when is_float(value), do: RDF.XSD.Double.new(value)
  def coerce(%Decimal{} = value), do: RDF.XSD.Decimal.new(value)
  def coerce(%Date{} = value), do: RDF.XSD.Date.new(value)
  def coerce(%Time{} = value), do: RDF.XSD.Time.new(value)
  def coerce(%DateTime{} = value), do: RDF.XSD.DateTime.new(value)
  def coerce(%NaiveDateTime{} = value), do: RDF.XSD.DateTime.new(value)
  def coerce(%URI{} = value), do: RDF.XSD.AnyURI.new(value)

  def coerce(value) when maybe_ns_term(value) do
    case RDF.Namespace.resolve_term(value) do
      {:ok, iri} -> iri |> IRI.parse() |> coerce()
      _ -> nil
    end
  end

  # Although the following catch-all-clause for all structs could handle the builtin datatypes
  # we're generating dedicated clauses for them here, as they are approx. 15% faster
  Enum.each(Datatype.Registry.builtin_datatypes(), fn datatype ->
    def coerce(%unquote(datatype){} = datatype_literal) do
      %__MODULE__{literal: datatype_literal}
    end
  end)

  def coerce(%datatype{} = datatype_literal) do
    if Datatype.Registry.datatype_struct?(datatype) do
      %__MODULE__{literal: datatype_literal}
    end
  end

  def coerce(_), do: nil

  @doc """
  Creates a new `RDF.Literal`, but fails if it's not valid.

  Note: Validation is only possible if an `RDF.Datatype` with an implementation of
    `RDF.Datatype.valid?/1` exists.

  ## Examples

      iex> RDF.Literal.new("foo")
      %RDF.Literal{literal: %RDF.XSD.String{value: "foo"}}

      iex> RDF.Literal.new!("foo", datatype: RDF.NS.XSD.integer)
      ** (RDF.Literal.InvalidError) invalid RDF.Literal: %RDF.XSD.Integer{value: nil, lexical: "foo"}

      iex> RDF.Literal.new!("foo", datatype: RDF.langString)
      ** (RDF.Literal.InvalidError) invalid RDF.Literal: %RDF.LangString{value: "foo", language: nil}

  """
  @spec new!(t | any, keyword) :: t
  def new!(value, opts \\ []) do
    literal = new(value, opts)

    if valid?(literal) do
      literal
    else
      raise RDF.Literal.InvalidError, "invalid RDF.Literal: #{inspect(literal.literal)}"
    end
  end

  @doc """
  Returns if the given value is a `RDF.Literal` or `RDF.Literal.Datatype` struct.

  If you simply want to check for a `RDF.Literal` use pattern matching or `RDF.literal?/1`.
  This function is a bit slower than those and most of the time only needed when
  implementing `RDF.Literal.Datatype`s where you have to deal with the raw,
  i.e. unwrapped `RDF.Literal.Datatype` structs.
  """
  defdelegate datatype?(value), to: RDF.Literal.Datatype.Registry, as: :datatype?

  @doc """
  Checks if 'literal' is literal with the given `datatype`.

  `datatype` can be one of the following:

  - a `RDF.Literal.Datatype` module  which checks if the literal is of this datatype or derived from it
  - `RDF.XSD.Numeric` which checks if the literal is one of the numeric XSD datatypes or derived of one of them
  - `RDF.XSD.Datatype` which checks if the literal is a XSD datatype or derived of one of them

  """
  # credo:disable-for-lines:5 Credo.Check.Readability.PredicateFunctionNames
  def is_a?(literal, RDF.XSD.Numeric), do: RDF.XSD.Numeric.datatype?(literal)
  def is_a?(literal, RDF.XSD.Datatype), do: RDF.XSD.datatype?(literal)
  def is_a?(literal, RDF.Literal.Datatype), do: datatype?(literal)
  def is_a?(literal, datatype), do: datatype?(datatype) and datatype.datatype?(literal)

  @doc """
  Returns if the literal uses the `RDF.Literal.Generic` datatype or on of the dedicated builtin or custom `RDF.Literal.Datatype`s.
  """
  @spec generic?(t) :: boolean
  def generic?(%__MODULE__{literal: %RDF.Literal.Generic{}}), do: true
  def generic?(%__MODULE__{}), do: false

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
  def simple?(%__MODULE__{literal: %RDF.XSD.String{}}), do: true
  def simple?(%__MODULE__{}), do: false

  @doc """
  Returns if a literal is a plain literal.

  A plain literal may have a language, but may not have a datatype.
  For all practical purposes, this includes `xsd:string` literals too.

  see <http://www.w3.org/TR/rdf-concepts/#dfn-plain-literal>
  """
  @spec plain?(t) :: boolean
  def plain?(%__MODULE__{literal: %RDF.XSD.String{}}), do: true
  def plain?(%__MODULE__{literal: %LangString{}}), do: true
  def plain?(%__MODULE__{}), do: false

  ############################################################################
  # functions delegating to the RDF.Literal.Datatype of a RDF.Literal

  @doc """
  Returns the IRI of datatype of the given `literal`.
  """
  @spec datatype_id(t) :: IRI.t()
  def datatype_id(%__MODULE__{literal: %datatype{} = literal}), do: datatype.datatype_id(literal)

  @doc """
  Returns the language of the given `literal` if present.
  """
  @spec language(t) :: String.t() | nil
  def language(%__MODULE__{literal: %datatype{} = literal}), do: datatype.language(literal)

  @doc """
  Returns the value of the given `literal`.
  """
  @spec value(t) :: any
  def value(%__MODULE__{literal: %datatype{} = literal}), do: datatype.value(literal)

  @doc """
  Returns the lexical form of the given `literal`.
  """
  @spec lexical(t) :: String.t()
  def lexical(%__MODULE__{literal: %datatype{} = literal}), do: datatype.lexical(literal)

  @doc """
  Transforms the given `literal` into its canonical form.
  """
  @spec canonical(t) :: t
  def canonical(%__MODULE__{literal: %datatype{} = literal}), do: datatype.canonical(literal)

  @doc """
  Returns the canonical lexical of the given `literal`.
  """
  @spec canonical_lexical(t) :: String.t() | nil
  def canonical_lexical(%__MODULE__{literal: %datatype{} = literal}),
    do: datatype.canonical_lexical(literal)

  @doc """
  Returns if the lexical form of the given `literal` has the canonical form.
  """
  @spec canonical?(t) :: boolean
  def canonical?(%__MODULE__{literal: %datatype{} = literal}), do: datatype.canonical?(literal)

  @doc """
  Returns if the given `literal` is valid with respect to its datatype.
  """
  @spec valid?(t | any) :: boolean
  def valid?(%__MODULE__{literal: %datatype{} = literal}), do: datatype.valid?(literal)
  def valid?(_), do: false

  @doc """
  Checks if two literals are equal.

  Two literals are equal if they have the same datatype, value and lexical form.
  """
  @spec equal?(any, any) :: boolean
  def equal?(left, right), do: left == right

  @doc """
  Checks if two literals have equal values.
  """
  @spec equal_value?(t, t | any) :: boolean
  def equal_value?(%__MODULE__{literal: %datatype{} = left}, right),
    do: datatype.equal_value?(left, right)

  def equal_value?(left, right) when not is_nil(left),
    do: equal_value?(coerce(left), right)

  def equal_value?(_, _), do: nil

  @spec compare(t, t) :: Datatype.comparison_result() | :indeterminate | nil
  def compare(%__MODULE__{literal: %datatype{} = left}, right) do
    datatype.compare(left, right)
  end

  @doc """
  Checks if the first of two `RDF.Literal`s is smaller than the other.
  """
  @spec less_than?(t, t) :: boolean
  def less_than?(left, right) do
    compare(left, right) == :lt
  end

  @doc """
  Checks if the first of two `RDF.Literal`s is greater than the other.
  """
  @spec greater_than?(t, t) :: boolean
  def greater_than?(left, right) do
    compare(left, right) == :gt
  end

  @doc """
  Matches the lexical form of the given `RDF.Literal` against a XPath and XQuery regular expression pattern with flags.

  The regular expression language is defined in _XQuery 1.0 and XPath 2.0 Functions and Operators_.

  see <https://www.w3.org/TR/xpath-functions/#func-matches>
  """
  @spec matches?(t | String.t(), pattern :: t | String.t(), flags :: t | String.t()) :: boolean
  def matches?(value, pattern, flags \\ "")

  def matches?(%__MODULE__{} = literal, pattern, flags),
    do: matches?(lexical(literal), pattern, flags)

  def matches?(value, %__MODULE__{literal: %RDF.XSD.String{}} = pattern, flags),
    do: matches?(value, lexical(pattern), flags)

  def matches?(value, pattern, %__MODULE__{literal: %RDF.XSD.String{}} = flags),
    do: matches?(value, pattern, lexical(flags))

  def matches?(value, pattern, flags)
      when is_binary(value) and is_binary(pattern) and is_binary(flags),
      do: RDF.XSD.Utils.Regex.matches?(value, pattern, flags)

  @doc """
  Updates the value of a `RDF.Literal` without changing everything else.

  The optional second argument allows to specify what will be passed to `fun` with the `:as` option,
  e.g. with `as: :lexical` the lexical is passed to the function.

  ## Example

      iex> RDF.XSD.integer(42) |> RDF.Literal.update(fn value -> value + 1 end)
      RDF.XSD.integer(43)
      iex> ~L"foo"de |> RDF.Literal.update(fn _ -> "bar" end)
      ~L"bar"de
      iex> RDF.literal("foo", datatype: "http://example.com/dt") |> RDF.Literal.update(fn _ -> "bar" end)
      RDF.literal("bar", datatype: "http://example.com/dt")
      iex> RDF.XSD.integer(42) |> RDF.XSD.Integer.update(
      ...>   fn value -> value <> "1" end, as: :lexical)
      RDF.XSD.integer(421)
  """
  def update(%__MODULE__{literal: %datatype{} = literal}, fun, opts \\ []) do
    datatype.update(literal, fun, opts)
  end

  defimpl String.Chars do
    def to_string(literal) do
      String.Chars.to_string(literal.literal)
    end
  end
end
