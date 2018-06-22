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

  @xsd_decimal XSD.decimal
  @xsd_double XSD.double


  @doc """
  The list of all numeric datatypes.
  """
  def types(), do: MapSet.to_list(@types)

  @doc """
  Returns if a given datatype is a numeric datatype.
  """
  def type?(type), do: MapSet.member?(@types, type)

  @doc """
  Returns if a given literal has a numeric datatype.
  """
  def literal?(%Literal{datatype: datatype}), do: type?(datatype)
  def literal?(_),                            do: false


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
      left == right
    end
  end

  def equal_value?(_, _), do: nil

  defp equal_decimal_value?(%D{} = left, %D{} = right), do: D.equal?(left, right)
  defp equal_decimal_value?(%D{} = left, right), do: equal_decimal_value?(left, D.new(right))
  defp equal_decimal_value?(left, %D{} = right), do: equal_decimal_value?(D.new(left), right)
  defp equal_decimal_value?(_, _), do: nil


  def zero?(%Literal{value: value}), do: zero_value?(value)

  defp zero_value?(zero) when zero == 0, do: true
  defp zero_value?(%D{coef: 0}), do: true
  defp zero_value?(_), do: false


  def negative_zero?(%Literal{value: zero, uncanonical_lexical: "-" <> _, datatype: @xsd_double})
    when zero == 0, do: true

  def negative_zero?(%Literal{value: %D{sign: -1, coef: 0}}), do: true

  def negative_zero?(_), do: false


  @doc """
  Adds two numeric literals.

  For `xsd:float` or `xsd:double` values, if one of the operands is a zero or a
  finite number and the other is INF or -INF, INF or -INF is returned. If both
  operands are INF, INF is returned. If both operands are -INF, -INF is returned.
  If one of the operands is INF and the other is -INF, NaN is returned.

  If one of the given arguments is not a numeric literal, `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-numeric-add>

  """
  def add(arg1, arg2) do
    arithmetic_operation :+, arg1, arg2, fn
      :positive_infinity, :negative_infinity, _ -> :nan
      :negative_infinity, :positive_infinity, _ -> :nan
      :positive_infinity, _, _                  -> :positive_infinity
      _, :positive_infinity, _                  -> :positive_infinity
      :negative_infinity, _, _                  -> :negative_infinity
      _, :negative_infinity, _                  -> :negative_infinity
      %D{} = arg1, %D{} = arg2, _               -> D.add(arg1, arg2)
      arg1, arg2, _                             -> arg1 + arg2
    end
  end

  @doc """
  Subtracts two numeric literals.

  For `xsd:float` or `xsd:double` values, if one of the operands is a zero or a
  finite number and the other is INF or -INF, an infinity of the appropriate sign
  is returned. If both operands are INF or -INF, NaN is returned. If one of the
  operands is INF and the other is -INF, an infinity of the appropriate sign is
  returned.

  If one of the given arguments is not a numeric literal, `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-numeric-subtract>

  """
  def subtract(arg1, arg2) do
    arithmetic_operation :-, arg1, arg2, fn
      :positive_infinity, :positive_infinity, _ -> :nan
      :negative_infinity, :negative_infinity, _ -> :nan
      :positive_infinity, :negative_infinity, _ -> :positive_infinity
      :negative_infinity, :positive_infinity, _ -> :negative_infinity
      :positive_infinity, _, _                  -> :positive_infinity
      _, :positive_infinity, _                  -> :negative_infinity
      :negative_infinity, _, _                  -> :negative_infinity
      _, :negative_infinity, _                  -> :positive_infinity
      %D{} = arg1, %D{} = arg2, _               -> D.sub(arg1, arg2)
      arg1, arg2, _                             -> arg1 - arg2
    end
  end

  @doc """
  Multiplies two numeric literals.

  For `xsd:float` or `xsd:double` values, if one of the operands is a zero and
  the other is an infinity, NaN is returned. If one of the operands is a non-zero
  number and the other is an infinity, an infinity with the appropriate sign is
  returned.

  If one of the given arguments is not a numeric literal, `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-numeric-multiply>

  """
  def multiply(arg1, arg2) do
    arithmetic_operation :*, arg1, arg2, fn
      :positive_infinity, :negative_infinity, _ -> :nan
      :negative_infinity, :positive_infinity, _ -> :nan
      inf, zero, _ when inf in [:positive_infinity, :negative_infinity] and zero == 0 -> :nan
      zero, inf, _ when inf in [:positive_infinity, :negative_infinity] and zero == 0 -> :nan
      :positive_infinity, number, _ when number < 0 -> :negative_infinity
      number, :positive_infinity, _ when number < 0 -> :negative_infinity
      :positive_infinity, _, _                      -> :positive_infinity
      _, :positive_infinity, _                      -> :positive_infinity
      :negative_infinity, number, _ when number < 0 -> :positive_infinity
      number, :negative_infinity, _ when number < 0 -> :positive_infinity
      :negative_infinity, _, _                      -> :negative_infinity
      _, :negative_infinity, _                      -> :negative_infinity
      %D{} = arg1, %D{} = arg2, _ -> D.mult(arg1, arg2)
      arg1, arg2, _               -> arg1 * arg2
    end
  end

  @doc """
  Divides two numeric literals.

  For `xsd:float` and `xsd:double` operands, floating point division is performed 
  as specified in [IEEE 754-2008]. A positive number divided by positive zero
  returns INF. A negative number divided by positive zero returns -INF. Division
  by negative zero returns -INF and INF, respectively. Positive or negative zero
  divided by positive or negative zero returns NaN. Also, INF or -INF divided by
  INF or -INF returns NaN.

  If one of the given arguments is not a numeric literal, `nil` is returned.

  'nil` is also returned for `xsd:decimal` and `xsd:integer` operands, if the
  divisor is (positive or negative) zero.

  see <http://www.w3.org/TR/xpath-functions/#func-numeric-divide>

  """
  def divide(arg1, arg2) do
    negative_zero = negative_zero?(arg2)
    arithmetic_operation :/, arg1, arg2, fn
      inf1, inf2, _ when inf1 in [:positive_infinity, :negative_infinity] and
                         inf2 in [:positive_infinity, :negative_infinity] ->
        :nan
      %D{} = arg1, %D{coef: coef} = arg2, _ ->
        unless coef == 0, do: D.div(arg1, arg2)
      arg1, arg2, result_type ->
        if zero_value?(arg2) do
          cond do
            not result_type in [XSD.double] -> nil  # TODO: or XSD.float
            zero_value?(arg1)          -> :nan
            negative_zero and arg1 < 0 -> :positive_infinity
            negative_zero              -> :negative_infinity
            arg1 < 0                   -> :negative_infinity
            true                       -> :positive_infinity
          end
        else
          arg1 / arg2
        end
    end
  end


  defp arithmetic_operation(op, arg1, arg2, fun) do
    if literal?(arg1) && literal?(arg2) do
      with result_type  = result_type(op, arg1.datatype, arg2.datatype),
           {arg1, arg2} = type_conversion(arg1, arg2, result_type),
           result       = fun.(arg1.value, arg2.value, result_type)
      do
        unless is_nil(result),
          do: Literal.new(result, datatype: result_type)
      end
    end
  end


  defp type_conversion(%Literal{datatype: @xsd_decimal} = arg1,
                       %Literal{value: arg2}, @xsd_decimal),
    do: {arg1, RDF.decimal(arg2)}

  defp type_conversion(%Literal{value: arg1},
                       %Literal{datatype: @xsd_decimal} = arg2, @xsd_decimal),
    do: {RDF.decimal(arg1), arg2}

  defp type_conversion(%Literal{datatype: @xsd_decimal, value: arg1}, arg2, @xsd_double),
    do: {arg1 |> D.to_float() |> RDF.double(), arg2}

  defp type_conversion(arg1, %Literal{datatype: @xsd_decimal, value: arg2}, @xsd_double),
    do: {arg1, arg2 |> D.to_float() |> RDF.double()}

  defp type_conversion(arg1, arg2, _), do: {arg1, arg2}


  defp result_type(:/, type1, type2) do
    types = [type1, type2]
    cond do
      XSD.double  in types -> XSD.double
      XSD.float   in types -> XSD.float
      true                 -> XSD.decimal
    end
  end

  defp result_type(_, type1, type2) do
    types = [type1, type2]
    cond do
      XSD.double  in types -> XSD.double
      XSD.float   in types -> XSD.float
      XSD.decimal in types -> XSD.decimal
      true                 -> XSD.integer
    end
  end
end
