defmodule RDF.Numeric do
  @moduledoc """
  The set of all numeric datatypes.
  """

  alias RDF.Literal
  alias RDF.Datatype.NS.XSD

  alias Elixir.Decimal, as: D

  @types MapSet.new [
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
  def types(), do: MapSet.to_list(@types)

  @doc """
  Returns if a given datatype is a numeric datatype.
  """
  def type?(type), do: MapSet.member?(@types, type)

  @xsd_decimal XSD.decimal

  @doc """
  Tests for numeric value equality of two numeric literals.

  Returns `nil` when the given arguments are not comparable as numeric literals.

  see:

  - <https://www.w3.org/TR/sparql11-query/#OperatorMapping>
  - <https://www.w3.org/TR/xpath-functions/#func-numeric-equal>
  """
  def equal_value?(left, right)

  def equal_value?(%Literal{datatype: left_datatype, value: left},
                   %Literal{datatype: right_datatype, value: right})
      when left_datatype == @xsd_decimal or right_datatype == @xsd_decimal,
      do: equal_decimal_value?(left, right)

  def equal_value?(%Literal{datatype: left_datatype, value: left},
                   %Literal{datatype: right_datatype, value: right})
  do
    if type?(left_datatype) and type?(right_datatype) do
      # We rely here on Elixirs numeric equality comparison.
      # TODO:  There are probably problematic edge-case, which might require an
      # TODO:  implementation of XPath type promotion and subtype substitution
      # - https://www.w3.org/TR/xpath-functions/#op.numeric
      # - https://www.w3.org/TR/xpath20/#id-type-promotion-and-operator-mapping
      left == right
    end
  end

  def equal_value?(_, _), do: nil

  defp equal_decimal_value?(%D{} = left, %D{} = right), do: D.equal?(left, right)
  defp equal_decimal_value?(%D{} = left, right), do: equal_decimal_value?(left, D.new(right))
  defp equal_decimal_value?(left, %D{} = right), do: equal_decimal_value?(D.new(left), right)
  defp equal_decimal_value?(_, _), do: nil

end
