defmodule RDF.Literal do
  @moduledoc """
  RDF literals are leaf nodes of a RDF graph containing raw data, like strings and numbers.
  """
  defstruct [:value, :uncanonical_lexical, :datatype, :language]

  @type t :: module

  alias RDF.Datatype.NS.XSD

  # to be able to pattern-match on plain types
  @xsd_string  XSD.string
  @lang_string RDF.langString
  @plain_types [@xsd_string, @lang_string]


  @doc """
  Creates a new `RDF.Literal` of the given value and tries to infer an appropriate XSD datatype.

  Note: The `RDF.literal` function is a shortcut to this function.

  The following mapping of Elixir types to XSD datatypes is applied:

  | Elixir type     | XSD datatype |
  | :-------------- | :----------- |
  | `string`        | `string`     |
  | `boolean`       | `boolean`    |
  | `integer`       | `integer`    |
  | `float`         | `double`     |
  | `Time`          | `time`       |
  | `Date`          | `date`       |
  | `DateTime`      | `dateTime`   |
  | `NaiveDateTime` | `dateTime`   |


  # Examples

      iex> RDF.Literal.new(42)
      %RDF.Literal{value: 42, datatype: XSD.integer}

  """
  def new(value)

  def new(value) when is_binary(value),  do: RDF.String.new(value)
  def new(value) when is_boolean(value), do: RDF.Boolean.new(value)
  def new(value) when is_integer(value), do: RDF.Integer.new(value)
  def new(value) when is_float(value),   do: RDF.Double.new(value)

# TODO:
  def new(%Date{} = date), do: %RDF.Literal{value: date, datatype: XSD.date}
  def new(%Time{} = time), do: %RDF.Literal{value: time, datatype: XSD.time}
#  def new(%Date{} = value),              do: RDF.Date.new(value)
#  def new(%Time{} = value),              do: RDF.Time.new(value)
  def new(%DateTime{} = value),          do: RDF.DateTime.new(value)
  def new(%NaiveDateTime{} = value),     do: RDF.DateTime.new(value)


  def new(value) do
    raise RDF.InvalidLiteralError, "#{inspect value} not convertible to a RDF.Literal"
  end

  def new(value, opts) when is_list(opts),
    do: new(value, Map.new(opts))

  def new(value, %{language: language} = opts) when not is_nil(language) do
    if is_binary(value) do
      if opts[:datatype] in [nil, RDF.langString] do
        RDF.LangString.new(value, opts)
      else
        raise ArgumentError, "datatype with language must be rdf:langString"
      end
    else
      new(value, Map.delete(opts, :language)) # Should we raise a warning?
    end
  end

  def new(value, %{datatype: %URI{} = id} = opts) do
    case RDF.Datatype.get(id) do
      nil      -> %RDF.Literal{value: value, datatype: id}
      datatype -> datatype.new(value, opts)
    end
  end

  def new(value, %{datatype: datatype} = opts),
    do: new(value, %{opts | datatype: RDF.uri(datatype)})

  def new(value, opts) when is_map(opts) and map_size(opts) == 0,
    do: new(value)


  def lexical(%RDF.Literal{value: value, uncanonical_lexical: nil, datatype: id} = literal) do
    case RDF.Datatype.get(id) do
      nil      -> to_string(value)
      datatype -> datatype.lexical(literal)
    end
  end

  def lexical(%RDF.Literal{uncanonical_lexical: lexical}), do: lexical


  def canonical(%RDF.Literal{uncanonical_lexical: nil} = literal), do: literal
  def canonical(%RDF.Literal{datatype: id} = literal) do
    case RDF.Datatype.get(id) do
      nil      -> literal
      datatype -> datatype.canonical(literal)
    end
  end


  def canonical?(%RDF.Literal{uncanonical_lexical: nil}), do: true
  def canonical?(_),                                      do: false


  def valid?(%RDF.Literal{datatype: id} = literal) do
    case RDF.Datatype.get(id) do
      nil      -> true
      datatype -> datatype.valid?(literal)
    end
  end


  @doc """
  Checks if a literal is a simple literal.

  A simple literal has no datatype or language.

  see <http://www.w3.org/TR/sparql11-query/#simple_literal>
  """
  def simple?(%RDF.Literal{datatype: @xsd_string}), do: true
  def simple?(_), do: false


  @doc """
  Checks if a literal is a language-tagged literal.

  see <http://www.w3.org/TR/rdf-concepts/#dfn-plain-literal>
  """
  def has_language?(%RDF.Literal{datatype: @lang_string}), do: true
  def has_language?(_), do: false


  @doc """
  Checks if a literal is a datatyped literal.

  For historical reasons, this excludes `xsd:string` and `rdf:langString`.

  see <http://www.w3.org/TR/rdf-concepts/#dfn-typed-literal>
  """
  def has_datatype?(literal) do
    not plain?(literal) and not has_language?(literal)
  end


  @doc """
  Checks if a literal is a plain literal.

  A plain literal may have a language, but may not have a datatype.
  For all practical purposes, this includes `xsd:string` literals too.

  see <http://www.w3.org/TR/rdf-concepts/#dfn-plain-literal>
  """
  def plain?(%RDF.Literal{datatype: datatype})
    when datatype in @plain_types, do: true
  def plain?(_), do: false

  def typed?(literal), do: not plain?(literal)

end

defimpl String.Chars, for: RDF.Literal do
  def to_string(literal) do
    RDF.Literal.lexical(literal)
  end
end
