defmodule RDF.Literal do
  @moduledoc """
  RDF literals are leaf nodes of a RDF graph containing raw data, like strings and numbers.
  """
  defstruct [:value, :datatype, :language]

  @type t :: module

  # Since the capability of RDF.Vocabulary.Namespaces requires the compilation
  # of the RDF.NTriples.Decoder and the RDF.NTriples.Decoder depends on RDF.Literals,
  # we can't define the XSD namespace in RDF.NS.
  defmodule NS do
    @moduledoc false
    @vocabdoc false
    use RDF.Vocabulary.Namespace
    defvocab XSD,
      base_uri:   "http://www.w3.org/2001/XMLSchema#",
      terms: ~w[
        string
          normalizedString
            token
              language
              Name
                NCName
                  ID
                  IDREF
                    IDREFS
                  ENTITY
                    ENTITIES
              NMTOKEN
                NMTOKENS
        boolean
        float
        double
        decimal
          integer
            long
              int
                short
                  byte
            nonPositiveInteger
              negativeInteger
            nonNegativeInteger
              positiveInteger
              unsignedLong
                unsignedInt
                  unsignedShort
                    unsignedByte
        duration
        dateTime
        time
        date
        gYearMonth
        gYear
        gMonthDay
        gDay
        gMonth
        base64Binary
        hexBinary
        anyURI
        QName
        NOTATION
      ]
  end
  alias NS.XSD


  @doc """
  Creates a new `RDF.Literal` of the given value and tries to infer an appropriate XSD datatype.

  Note: The `RDF.literal` function is a shortcut to this function.

  The following mapping of Elixir types to XSD datatypes is applied:

  | Elixir type | XSD datatype |
  | :---------- | :----------- |
  | string      |              |
  | boolean     | `boolean`    |
  | integer     | `integer`    |
  | float       | `float`      |
  | atom        |              |
  | ...         |              |


  # Examples

      iex> RDF.Literal.new(42)
      %RDF.Literal{value: 42, language: nil, datatype: RDF.uri(XSD.integer)}

  """
  def new(value)

  def new(value) when is_binary(value),
    do: %RDF.Literal{value: value, datatype: XSD.string}
  def new(value) when is_boolean(value),
    do: %RDF.Literal{value: value, datatype: XSD.boolean}
  def new(value) when is_integer(value),
    do: %RDF.Literal{value: value, datatype: XSD.integer}
  def new(value) when is_float(value),
    do: %RDF.Literal{value: value, datatype: XSD.float}

#  def new(value) when is_atom(value), do:
#  def new(value) when is_bitstring(value), do:

#  def new(value) when is_list(value), do:
#  def new(value) when is_tuple(value), do:
#  def new(value) when is_map(value), do:

#  def new(value) when is_function(value), do:
#  def new(value) when is_pid(value), do:
#  def new(value) when is_port(value), do:
#  def new(value) when is_reference(value), do:

  def new(value) do
    raise RDF.InvalidLiteralError, "#{inspect value} not convertible to a RDF.Literal"
  end

  def new(value, opts) when is_list(opts),
    do: new(value, Map.new(opts))

  def new(value, %{language: language}) when not is_nil(language) and is_binary(value) do
    %RDF.Literal{value: value, datatype: RDF.langString, language: language}
  end

  def new(value, %{datatype: %URI{} = datatype}) when is_binary(value) do
    cond do
      datatype == XSD.string  -> %RDF.Literal{value: value, datatype: datatype}
      datatype == XSD.integer -> %RDF.Literal{value: String.to_integer(value), datatype: datatype}
# TODO:     datatype == XSD.byte    -> nil # %RDF.Literal{value: String.to_integer(value), datatype: datatype}
# TODO:     datatype == RDF.uri(RDFS.XMLLiteral) -> nil # %RDF.Literal{value: String.to_integer(value), datatype: datatype}
      # TODO: Should we support more values, like "1" etc.?
      # TODO: Should we exclude any non-useful value?
      datatype == XSD.boolean -> %RDF.Literal{value: String.downcase(value) == "true", datatype: datatype}
      true -> %RDF.Literal{value: value, datatype: datatype}
    end
  end

  def new(value, %{datatype: %URI{} = datatype}) when is_integer(value) do
    cond do
      datatype == XSD.string  -> %RDF.Literal{value: to_string(value), datatype: datatype}
      datatype == XSD.integer -> %RDF.Literal{value: value, datatype: datatype}
    end
  end

  def new(value, %{datatype: %URI{} = datatype}) when is_boolean(value) do
    cond do
      datatype == XSD.boolean -> %RDF.Literal{value: value, datatype: datatype}
      # TODO: Should we exclude any non-useful value?
      datatype == XSD.string  -> %RDF.Literal{value: to_string(value), datatype: datatype}
      datatype == XSD.integer -> %RDF.Literal{value: (if value, do: 1, else: 0), datatype: datatype}
    end
  end

  def new(value, %{datatype: datatype}) do
    new(value, datatype: RDF.uri(datatype))
  end

end
