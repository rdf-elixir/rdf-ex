defmodule RDF.Literal do
  @moduledoc """
  RDF literals are leaf nodes of a RDF graph containing raw data, like strings and numbers.
  """
  defstruct [:value, :datatype, :language]

  @type t :: module

  alias RDF.XSD

  defmodule InvalidLiteralError, do: defexception [:message]

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

  def new(value) when is_boolean(value),
    do: %RDF.Literal{value: value, datatype: XSD.boolean}
  def new(value) when is_integer(value),
    do: %RDF.Literal{value: value, datatype: XSD.integer}
  def new(value) when is_float(value),
    do: %RDF.Literal{value: value, datatype: XSD.float}

#  def new(value) when is_atom(value), do:
#  def new(value) when is_binary(value), do:
#  def new(value) when is_bitstring(value), do:

#  def new(value) when is_list(value), do:
#  def new(value) when is_tuple(value), do:
#  def new(value) when is_map(value), do:

#  def new(value) when is_function(value), do:
#  def new(value) when is_pid(value), do:
#  def new(value) when is_port(value), do:
#  def new(value) when is_reference(value), do:

  def new(value) do
    raise InvalidLiteralError, "#{inspect value} not convertible to a RDF.Literal"
  end

end
