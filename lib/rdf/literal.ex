defmodule RDF.Literal do
  @moduledoc """
  RDF literals are leaf nodes of a RDF graph containing raw data, like strings and numbers.
  """
  defstruct [:value, :datatype, :language]

  @type t :: module

  alias RDF.{XSD, RDFS}

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
      %RDF.Literal{value: 42, language: nil, datatype: RDF.uri(RDF.XSD.integer)}

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

  def new(value, language: language) when is_binary(value) do
    %RDF.Literal{value: value, datatype: RDF.langString, language: language}
  end

  def new(value, datatype: datatype) when is_binary(value) do
    datatype_uri = RDF.uri(datatype)
    cond do
      datatype_uri == XSD.string  -> %RDF.Literal{value: value, datatype: datatype_uri}
      datatype_uri == XSD.integer -> %RDF.Literal{value: String.to_integer(value), datatype: datatype_uri}
# TODO:     datatype_uri == XSD.byte    -> nil # %RDF.Literal{value: String.to_integer(value), datatype: datatype_uri}
# TODO:     datatype_uri == RDF.uri(RDFS.XMLLiteral) -> nil # %RDF.Literal{value: String.to_integer(value), datatype: datatype_uri}
      # TODO: Should we support more values, like "1" etc.?
      # TODO: Should we exclude any non-useful value?
      datatype_uri == XSD.boolean -> %RDF.Literal{value: String.downcase(value) == "true", datatype: datatype_uri}
      true -> %RDF.Literal{value: value, datatype: datatype_uri}
    end
  end

  def new(value, datatype: datatype) when is_integer(value) do
    datatype_uri = RDF.uri(datatype)
    cond do
      datatype_uri == XSD.string  -> %RDF.Literal{value: to_string(value), datatype: datatype_uri}
      datatype_uri == XSD.integer -> %RDF.Literal{value: value, datatype: datatype_uri}
    end
  end

  def new(value, datatype: datatype) when is_boolean(value) do
    datatype_uri = RDF.uri(datatype)
    cond do
      datatype_uri == XSD.boolean -> %RDF.Literal{value: value, datatype: datatype_uri}
      # TODO: Should we exclude any non-useful value?
      datatype_uri == XSD.string  -> %RDF.Literal{value: to_string(value), datatype: datatype_uri}
      datatype_uri == XSD.integer -> %RDF.Literal{value: (if value, do: 1, else: 0), datatype: datatype_uri}
    end
  end

end
