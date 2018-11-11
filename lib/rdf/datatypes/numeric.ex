defmodule RDF.Numeric do
  @moduledoc """
  The set of all numeric datatypes.
  """

  alias RDF.Literal
  alias RDF.Datatype.NS.XSD

  alias Elixir.Decimal, as: D

  import RDF.Literal.Guards
  import Kernel, except: [abs: 1]


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

  def equal_value?(%Literal{uncanonical_lexical: lexical1, datatype: dt, value: nil},
                   %Literal{uncanonical_lexical: lexical2, datatype: dt}) do
    lexical1 == lexical2
  end

  def equal_value?(%Literal{datatype: left_datatype, value: left},
                   %Literal{datatype: right_datatype, value: right})
      when is_xsd_decimal(left_datatype) or is_xsd_decimal(right_datatype),
      do: equal_decimal_value?(left, right)

  def equal_value?(%Literal{datatype: left_datatype, value: left},
                   %Literal{datatype: right_datatype, value: right}) do
    if type?(left_datatype) and type?(right_datatype) do
      left == right
    end
  end

  def equal_value?(%RDF.Literal{} = left, right) when not is_nil(right) do
    unless RDF.Term.term?(right) do
      equal_value?(left, RDF.Term.coerce(right))
    end
  end

  def equal_value?(_, _), do: nil

  defp equal_decimal_value?(%D{} = left, %D{} = right), do: D.equal?(left, right)
  defp equal_decimal_value?(%D{} = left, right), do: equal_decimal_value?(left, D.new(right))
  defp equal_decimal_value?(left, %D{} = right), do: equal_decimal_value?(D.new(left), right)
  defp equal_decimal_value?(_, _), do: nil


  @doc """
  Compares two numeric `RDF.Literal`s.

  Returns `:gt` if first literal is greater than the second and `:lt` for vice
  versa. If the two literals are equal `:eq` is returned.

  Returns `nil` when the given arguments are not comparable datatypes.

  """
  def compare(left, right)

  def compare(%Literal{datatype: left_datatype, value: left},
              %Literal{datatype: right_datatype, value: right})
      when is_xsd_decimal(left_datatype)
  do
    if type?(right_datatype) do
      compare_decimal_value(left, right)
    end
  end

  def compare(%Literal{datatype: left_datatype, value: left},
              %Literal{datatype: right_datatype, value: right})
      when is_xsd_decimal(right_datatype)
  do
    if type?(left_datatype) do
      compare_decimal_value(left, right)
    end
  end

  def compare(%Literal{datatype: left_datatype, value: left},
              %Literal{datatype: right_datatype, value: right})
      when not (is_nil(left) or is_nil(right))
  do
    if type?(left_datatype) and type?(right_datatype) do
      cond do
        left < right -> :lt
        left > right -> :gt
        true         -> :eq
      end
    end
  end

  def compare(_, _), do: nil

  defp compare_decimal_value(%D{} = left, %D{} = right), do: D.cmp(left, right)
  defp compare_decimal_value(%D{} = left, right), do: compare_decimal_value(left, D.new(right))
  defp compare_decimal_value(left, %D{} = right), do: compare_decimal_value(D.new(left), right)
  defp compare_decimal_value(_, _), do: nil


  def zero?(%Literal{value: value}), do: zero_value?(value)

  defp zero_value?(zero) when zero == 0, do: true
  defp zero_value?(%D{coef: 0}), do: true
  defp zero_value?(_), do: false


  def negative_zero?(%Literal{value: zero, uncanonical_lexical: "-" <> _, datatype: datatype})
    when zero == 0 and is_xsd_double(datatype), do: true

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

  `nil` is also returned for `xsd:decimal` and `xsd:integer` operands, if the
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
            result_type not in [XSD.double] -> nil  # TODO: or XSD.float
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

  @doc """
  Returns the absolute value of a numeric literal.

  If the argument is not a valid numeric literal `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-abs>

  """
  def abs(literal)

  def abs(%Literal{datatype: datatype} = literal) when is_xsd_decimal(datatype) do
    if RDF.Decimal.valid?(literal) do
      literal.value
      |> D.abs()
      |> RDF.Decimal.new()
    end
  end

  def abs(%Literal{datatype: datatype} = literal) do
    if type?(datatype) and Literal.valid?(literal) do
      case literal.value do
        :nan               -> literal
        :positive_infinity -> literal
        :negative_infinity -> Literal.new(:positive_infinity, datatype: datatype)
        value ->
          value
          |> Kernel.abs()
          |> Literal.new(datatype: datatype)
      end
    end
  end

  def abs(value) do
    if not is_nil(value) and not RDF.Term.term?(value) do
      value
      |> RDF.Term.coerce()
      |> abs()
    end
  end


  @doc """
  Rounds a value to a specified number of decimal places, rounding upwards if two such values are equally near.

  The function returns the nearest (that is, numerically closest) value to the
  given literal value that is a multiple of ten to the power of minus `precision`.
  If two such values are equally near (for example, if the fractional part in the
  literal value is exactly .5), the function returns the one that is closest to
  positive infinity.

  If the argument is not a valid numeric literal `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-round>

  """
  def round(literal, precision \\ 0)

  def round(%Literal{datatype: datatype} = literal, precision) when is_xsd_decimal(datatype) do
    if RDF.Decimal.valid?(literal) do
      literal.value
      |> xpath_round(precision)
      |> to_string()
      |> RDF.Decimal.new()
    end
  end

  def round(%Literal{datatype: datatype, value: value} = literal, _)
      when is_xsd_double(datatype) and value in ~w[nan positive_infinity negative_infinity]a,
      do: literal

  def round(%Literal{datatype: datatype} = literal, precision) when is_xsd_double(datatype) do
    if RDF.Double.valid?(literal) do
      literal.value
      |> D.new()
      |> xpath_round(precision)
      |> D.to_float()
      |> RDF.Double.new()
    end
  end

  def round(%Literal{datatype: datatype} = literal, precision) do
    if type?(datatype) and Literal.valid?(literal) do
      if precision < 0 do
        literal.value
        |> D.new()
        |> xpath_round(precision)
        |> D.to_integer()
        |> RDF.Integer.new()
      else
        literal
      end
    end
  end

  def round(value, precision) do
    if not is_nil(value) and not RDF.Term.term?(value) do
      value
      |> RDF.Term.coerce()
      |> round(precision)
    end
  end

  defp xpath_round(%D{sign: -1} = decimal, precision),
     do: D.round(decimal, precision, :half_down)
  defp xpath_round(decimal, precision),
     do: D.round(decimal, precision)

  @doc """
  Rounds a numeric literal upwards to a whole number literal.

  If the argument is not a valid numeric literal `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-ceil>

  """
  def ceil(literal)

  def ceil(%Literal{datatype: datatype} = literal) when is_xsd_decimal(datatype)do
    if RDF.Decimal.valid?(literal) do
      literal.value
      |> D.round(0, (if literal.value.sign == -1, do: :down, else: :up))
      |> D.to_string()
      |> RDF.Decimal.new()
    end
  end

  def ceil(%Literal{datatype: datatype, value: value} = literal)
      when is_xsd_double(datatype) and value in ~w[nan positive_infinity negative_infinity]a,
      do: literal

  def ceil(%Literal{datatype: datatype} = literal) when is_xsd_double(datatype) do
    if RDF.Double.valid?(literal) do
      literal.value
      |> Float.ceil()
      |> trunc()
      |> to_string()
      |> RDF.Double.new()
    end
  end

  def ceil(%Literal{datatype: datatype} = literal) do
    if type?(datatype) and Literal.valid?(literal) do
      literal
    end
  end

  def ceil(value) do
    if not is_nil(value) and not RDF.Term.term?(value) do
      value
      |> RDF.Term.coerce()
      |> ceil()
    end
  end

  @doc """
  Rounds a numeric literal downwards to a whole number literal.

  If the argument is not a valid numeric literal `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-floor>

  """
  def floor(literal)

  def floor(%Literal{datatype: datatype} = literal) when is_xsd_decimal(datatype)do
    if RDF.Decimal.valid?(literal) do
      literal.value
      |> D.round(0, (if literal.value.sign == -1, do: :up, else: :down))
      |> D.to_string()
      |> RDF.Decimal.new()
    end
  end

  def floor(%Literal{datatype: datatype, value: value} = literal)
      when is_xsd_double(datatype) and value in ~w[nan positive_infinity negative_infinity]a,
      do: literal

  def floor(%Literal{datatype: datatype} = literal) when is_xsd_double(datatype)do
    if RDF.Double.valid?(literal) do
      literal.value
      |> Float.floor()
      |> trunc()
      |> to_string()
      |> RDF.Double.new()
    end
  end

  def floor(%Literal{datatype: datatype} = literal) do
    if type?(datatype) and Literal.valid?(literal) do
      literal
    end
  end

  def floor(value) do
    if not is_nil(value) and not RDF.Term.term?(value) do
      value
      |> RDF.Term.coerce()
      |> floor()
    end
  end


  defp arithmetic_operation(op, %Literal{} = arg1, %Literal{} = arg2, fun) do
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

  defp arithmetic_operation(op, %Literal{} = arg1, arg2, fun) do
    if not is_nil(arg2) and not RDF.Term.term?(arg2) do
      arithmetic_operation(op, arg1, RDF.Term.coerce(arg2), fun)
    end
  end

  defp arithmetic_operation(op, arg1, %Literal{} = arg2, fun) do
    if not is_nil(arg1) and not RDF.Term.term?(arg1) do
      arithmetic_operation(op, RDF.Term.coerce(arg1), arg2, fun)
    end
  end

  defp arithmetic_operation(op, arg1, arg2, fun) do
    if not is_nil(arg1) and not RDF.Term.term?(arg1) and
       not is_nil(arg2) and not RDF.Term.term?(arg2) do
      arithmetic_operation(op, RDF.Term.coerce(arg1), RDF.Term.coerce(arg2), fun)
    end
  end


  defp type_conversion(%Literal{datatype: datatype} = arg1,
                       %Literal{value: arg2}, datatype) when is_xsd_decimal(datatype),
    do: {arg1, RDF.decimal(arg2)}

  defp type_conversion(%Literal{value: arg1},
                       %Literal{datatype: datatype} = arg2, datatype)
    when is_xsd_decimal(datatype),
    do: {RDF.decimal(arg1), arg2}

  defp type_conversion(%Literal{datatype: input_datatype, value: arg1}, arg2, output_datatype)
       when is_xsd_decimal(input_datatype) and is_xsd_double(output_datatype),
    do: {arg1 |> D.to_float() |> RDF.double(), arg2}

  defp type_conversion(arg1, %Literal{datatype: input_datatype, value: arg2}, output_datatype)
       when is_xsd_decimal(input_datatype) and is_xsd_double(output_datatype),
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
