defmodule RDF.Literal do
  @moduledoc """
  RDF literals are leaf nodes of a RDF graph containing raw data, like strings and numbers.
  """
  defstruct [:lexical, :value, :datatype, :language]

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
  | `string`        |  `string`    |
  | `boolean`       | `boolean`    |
  | `integer`       | `integer`    |
  | `float`         | `double`     |
  | `Time`          | `time`       |
  | `Date`          | `date`       |
  | `DateTime`      | `dateTime`   |
  | `NaiveDateTime` | `dateTime`   |


  # Examples

      iex> RDF.Literal.new(42)
      %RDF.Literal{value: 42, lexical: "42", datatype: XSD.integer}

  """
  def new(value)

  def new(value) when is_binary(value),  do: RDF.String.new(value)
  def new(value) when is_boolean(value), do: RDF.Boolean.new(value)
  def new(value) when is_integer(value), do: RDF.Integer.new(value)
  def new(value) when is_float(value),   do: RDF.Double.new(value)

# TODO:
#  def new(%Date{} = value),              do: RDF.Date.new(value)
#  def new(%Time{} = value),              do: RDF.Time.new(value)
#  def new(%DateTime{} = value),          do: RDF.DateTime.new(value)
#  def new(%NaiveDateTime{} = value),     do: RDF.DateTime.new(value)
  def new(%Date{} = date), do: %RDF.Literal{value: date, datatype: XSD.date}
  def new(%Time{} = time), do: %RDF.Literal{value: time, datatype: XSD.time}
  def new(%DateTime{} = datetime), do: %RDF.Literal{value: datetime, datatype: XSD.dateTime}
  def new(%NaiveDateTime{} = datetime), do: %RDF.Literal{value: datetime, datatype: XSD.dateTime}

  def new(value) do
    raise RDF.InvalidLiteralError, "#{inspect value} not convertible to a RDF.Literal"
  end

  def new(value, opts) when is_list(opts),
    do: new(value, Map.new(opts))

  def new(value, %{language: language} = opts) when not is_nil(language) and is_binary(value) do
    if not opts[:datatype] in [nil, RDF.langString] do
      raise ArgumentError, "datatype with language must be rdf:langString"
    else
      RDF.LangString.new(value, opts)
    end
  end

  def new(value, %{language: language} = opts) when not is_nil(language),
    do: new(value, Map.delete(opts, :language)) # Should we raise a warning?

  def new(value, %{datatype: %URI{} = id} = opts) do
    case RDF.Datatype.get(id) do
      nil           -> %RDF.Literal{value: value, datatype: id}
      literal_type  -> literal_type.new(value, opts)
    end
  end

  def new(value, %{datatype: datatype} = opts),
    do: new(value, %{opts | datatype: RDF.uri(datatype)})

  def new(value, opts) when is_map(opts) and map_size(opts) == 0,
    do: new(value)


  @doc """
  Checks if a literal is a simple literal.

  A simple literal has no datatype or language.

  see <http://www.w3.org/TR/sparql11-query/#simple_literal>
  """
  def simple?(%RDF.Literal{datatype: @xsd_string}), do: true
  def simple?(foo), do: false

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

#
end

defimpl String.Chars, for: RDF.Literal do
  # TODO: remove this when time types were implemented?
  def to_string(%RDF.Literal{lexical: nil, value: value}) do
    Kernel.to_string(value)
  end

  def to_string(%RDF.Literal{lexical: lexical}) do
    lexical
  end
end
