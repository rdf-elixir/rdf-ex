defmodule RDF.Numeric do
  @moduledoc """
  The set of all numeric datatypes.
  """

  alias RDF.Datatype.NS.XSD

  @types [
    XSD.integer,
    XSD.decimal,
    XSD.float,
    XSD.double,
    XSD.nonPositiveInteger,
    XSD.negativeInteger,
    XSD.long,
    XSD.int,
    XSD.short,
    XSD.byte,
    XSD.nonNegativeInteger,
    XSD.unsignedLong,
    XSD.unsignedInt,
    XSD.unsignedShort,
    XSD.unsignedByte,
    XSD.positiveInteger,
  ]

  @doc """
  The list of all numeric datatypes.
  """
  def types(), do: @types

  @doc """
  Returns if a given datatype is numeric.
  """
  def type?(type), do: type in @types

end
