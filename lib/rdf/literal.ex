defmodule RDF.Literal do
  @moduledoc """
  RDF literals are leaf nodes of a RDF graph containing raw data, like strings and numbers.
  """

  defstruct [:value, :uncanonical_lexical, :datatype, :language]

  @type t :: module

  alias RDF.Datatype.NS.XSD

  # to be able to pattern-match on plain types
  @xsd_string  XSD.string
  @lang_string RDF.iri("http://www.w3.org/1999/02/22-rdf-syntax-ns#langString")
  @plain_types [@xsd_string, @lang_string]


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
  | `Time`          | `xsd:time`     |
  | `Date`          | `xsd:date`     |
  | `DateTime`      | `xsd:dateTime` |
  | `NaiveDateTime` | `xsd:dateTime` |


  ## Examples

      iex> RDF.Literal.new(42)
      %RDF.Literal{value: 42, datatype: XSD.integer}

  """
  def new(value)

  def new(%RDF.Literal{} = literal),     do: literal

  def new(value) when is_binary(value),  do: RDF.String.new(value)
  def new(value) when is_boolean(value), do: RDF.Boolean.new(value)
  def new(value) when is_integer(value), do: RDF.Integer.new(value)
  def new(value) when is_float(value),   do: RDF.Double.new(value)

  def new(%Date{} = value),              do: RDF.Date.new(value)
  def new(%Time{} = value),              do: RDF.Time.new(value)
  def new(%DateTime{} = value),          do: RDF.DateTime.new(value)
  def new(%NaiveDateTime{} = value),     do: RDF.DateTime.new(value)


  def new(value) do
    raise RDF.Literal.InvalidError, "#{inspect value} not convertible to a RDF.Literal"
  end

  @doc """
  Creates a new `RDF.Literal` with the given datatype or language tag.
  """
  def new(value, opts)

  def new(value, opts) when is_list(opts),
    do: new(value, Map.new(opts))

  def new(value, %{language: nil} = opts),
    do: new(value, Map.delete(opts, :language))

  def new(value, %{language: _} = opts) do
    if is_binary(value) do
      if opts[:datatype] in [nil, @lang_string] do
        RDF.LangString.new(value, opts)
      else
        raise ArgumentError, "datatype with language must be rdf:langString"
      end
    else
      new(value, Map.delete(opts, :language)) # Should we raise a warning?
    end
  end

  def new(value, %{datatype: %RDF.IRI{} = id} = opts) do
    case RDF.Datatype.get(id) do
      nil      -> %RDF.Literal{value: value, datatype: id}
      datatype -> datatype.new(value, opts)
    end
  end

  def new(value, %{datatype: datatype} = opts),
    do: new(value, %{opts | datatype: RDF.iri(datatype)})

  def new(value, opts) when is_map(opts) and map_size(opts) == 0,
    do: new(value)


  @doc """
  Creates a new `RDF.Literal`, but fails if it's not valid.

  Note: Validation is only possible if an `RDF.Datatype` with an implementation of
    `RDF.Datatype.valid?/1` exists.

  ## Examples

      iex> RDF.Literal.new!("3.14", datatype: XSD.double) == RDF.Literal.new("3.14", datatype: XSD.double)
      true

      iex> RDF.Literal.new!("invalid", datatype: "http://example/unkown_datatype") == RDF.Literal.new("invalid", datatype: "http://example/unkown_datatype")
      true

      iex> RDF.Literal.new!("foo", datatype: XSD.integer)
      ** (RDF.Literal.InvalidError) invalid RDF.Literal: %RDF.Literal{value: nil, lexical: "foo", datatype: ~I<http://www.w3.org/2001/XMLSchema#integer>}

      iex> RDF.Literal.new!("foo", datatype: RDF.langString)
      ** (RDF.Literal.InvalidError) invalid RDF.Literal: %RDF.Literal{value: "foo", datatype: ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#langString>, language: nil}

  """
  def new!(value, opts \\ %{}) do
    with %RDF.Literal{} = literal <- new(value, opts) do
      if valid?(literal) do
        literal
      else
        raise RDF.Literal.InvalidError, "invalid RDF.Literal: #{inspect literal}"
      end
    else
      invalid ->
        raise RDF.Literal.InvalidError, "invalid result of RDF.Literal.new: #{inspect invalid}"
    end
  end

  @doc """
  Returns the lexical representation of the given literal according to its datatype.
  """
  def lexical(%RDF.Literal{value: value, uncanonical_lexical: nil, datatype: id} = literal) do
    case RDF.Datatype.get(id) do
      nil      -> to_string(value)
      datatype -> datatype.lexical(literal)
    end
  end

  def lexical(%RDF.Literal{uncanonical_lexical: lexical}), do: lexical

  @doc """
  Returns the given literal in its canonical lexical representation.
  """
  def canonical(%RDF.Literal{uncanonical_lexical: nil} = literal), do: literal
  def canonical(%RDF.Literal{datatype: id} = literal) do
    case RDF.Datatype.get(id) do
      nil      -> literal
      datatype -> datatype.canonical(literal)
    end
  end


  @doc """
  Returns if the given literal is in its canonical lexical representation.
  """
  def canonical?(%RDF.Literal{uncanonical_lexical: nil}), do: true
  def canonical?(_),                                      do: false


  @doc """
  Returns if the value of the given literal is a valid according to its datatype.
  """
  def valid?(%RDF.Literal{datatype: id} = literal) do
    case RDF.Datatype.get(id) do
      nil      -> true
      datatype -> datatype.valid?(literal)
    end
  end


  @doc """
  Returns if a literal is a simple literal.

  A simple literal has no datatype or language.

  see <http://www.w3.org/TR/sparql11-query/#simple_literal>
  """
  def simple?(%RDF.Literal{datatype: @xsd_string}), do: true
  def simple?(_), do: false


  @doc """
  Returns if a literal is a language-tagged literal.

  see <http://www.w3.org/TR/rdf-concepts/#dfn-plain-literal>
  """
  def has_language?(%RDF.Literal{datatype: @lang_string}), do: true
  def has_language?(_), do: false


  @doc """
  Returns if a literal is a datatyped literal.

  For historical reasons, this excludes `xsd:string` and `rdf:langString`.

  see <http://www.w3.org/TR/rdf-concepts/#dfn-typed-literal>
  """
  def has_datatype?(literal) do
    not plain?(literal) and not has_language?(literal)
  end


  @doc """
  Returns if a literal is a plain literal.

  A plain literal may have a language, but may not have a datatype.
  For all practical purposes, this includes `xsd:string` literals too.

  see <http://www.w3.org/TR/rdf-concepts/#dfn-plain-literal>
  """
  def plain?(%RDF.Literal{datatype: datatype})
    when datatype in @plain_types, do: true
  def plain?(_), do: false

  def typed?(literal), do: not plain?(literal)


  @doc """
  Checks if two `RDF.Literal`s of this datatype are equal.

  Returns `nil` when the given arguments are not comparable as Literals.

  see <https://www.w3.org/TR/rdf-concepts/#section-Literal-Equality>
  """
  def equal_value?(left, right)

  def equal_value?(%RDF.Literal{datatype: id1} = literal1, %RDF.Literal{datatype: id2} = literal2) do
    case RDF.Datatype.get(id1) do
      nil ->
        if id1 == id2 do
          literal1.value == literal2.value
        end
      datatype ->
        datatype.equal_value?(literal1, literal2)
    end
  end

  # TODO: Handle AnyURI in its own RDF.Datatype implementation
  @xsd_any_uri "http://www.w3.org/2001/XMLSchema#anyURI"

  def equal_value?(%RDF.Literal{datatype: %RDF.IRI{value: @xsd_any_uri}} = left, right),
    do: RDF.IRI.equal_value?(left, right)

  def equal_value?(left, %RDF.Literal{datatype: %RDF.IRI{value: @xsd_any_uri}} = right),
    do: RDF.IRI.equal_value?(left, right)

  def equal_value?(_, _), do: nil

end

defimpl String.Chars, for: RDF.Literal do
  def to_string(literal) do
    RDF.Literal.lexical(literal)
  end
end
