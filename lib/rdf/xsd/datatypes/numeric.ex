defmodule RDF.XSD.Numeric do
  @moduledoc """
  Collection of functions for numeric literals.
  """

  @type t :: module

  alias RDF.{XSD, Literal}
  alias Elixir.Decimal, as: D

  import Kernel, except: [abs: 1, floor: 1, ceil: 1]

  defdelegate datatype?(value), to: Literal.Datatype.Registry, as: :numeric_datatype?

  @doc !"""
       Tests for numeric value equality of two numeric XSD datatyped literals.

       see:

       - <https://www.w3.org/TR/sparql11-query/#OperatorMapping>
       - <https://www.w3.org/TR/xpath-functions/#func-numeric-equal>
       """
  @spec do_equal_value?(t() | any, t() | any) :: boolean
  def do_equal_value?(left, right)

  def do_equal_value?(%left_datatype{value: left}, %right_datatype{value: right}) do
    cond do
      XSD.Decimal.datatype?(left_datatype) or XSD.Decimal.datatype?(right_datatype) ->
        equal_decimal_value?(left, right)

      datatype?(left_datatype) and datatype?(right_datatype) ->
        left != :nan and right != :nan and left == right

      true ->
        nil
    end
  end

  def do_equal_value?(_, _), do: nil

  defp equal_decimal_value?(%D{} = left, %D{} = right), do: D.equal?(left, right)

  defp equal_decimal_value?(%D{} = left, right),
    do: equal_decimal_value?(left, new_decimal(right))

  defp equal_decimal_value?(left, %D{} = right),
    do: equal_decimal_value?(new_decimal(left), right)

  defp equal_decimal_value?(_, _), do: false

  defp new_decimal(value) when is_float(value), do: D.from_float(value)
  defp new_decimal(value), do: D.new(value)

  @doc !"""
       Compares two numeric XSD literals.

       Returns `:gt` if first literal is greater than the second and `:lt` for vice
       versa. If the two literals are equal `:eq` is returned.

       Returns `nil` when the given arguments are not comparable datatypes.

       """
  @spec do_compare(t, t) :: Literal.Datatype.comparison_result() | nil
  def do_compare(left, right)

  def do_compare(%left_datatype{value: left}, %right_datatype{value: right}) do
    if datatype?(left_datatype) and datatype?(right_datatype) do
      cond do
        XSD.Decimal.datatype?(left_datatype) or XSD.Decimal.datatype?(right_datatype) ->
          compare_decimal_value(left, right)

        left < right ->
          :lt

        left > right ->
          :gt

        true ->
          :eq
      end
    end
  end

  def do_compare(_, _), do: nil

  defp compare_decimal_value(%D{} = left, %D{} = right),
    do: D.compare(left, right)

  defp compare_decimal_value(%D{} = left, right),
    do: compare_decimal_value(left, new_decimal(right))

  defp compare_decimal_value(left, %D{} = right),
    do: compare_decimal_value(new_decimal(left), right)

  defp compare_decimal_value(_, _), do: nil

  @spec zero?(any) :: boolean
  def zero?(%Literal{literal: literal}), do: zero?(literal)
  def zero?(%{value: value}), do: zero_value?(value)
  defp zero_value?(zero) when zero == 0, do: true
  defp zero_value?(%D{coef: 0}), do: true
  defp zero_value?(_), do: false

  @spec negative_zero?(any) :: boolean
  def negative_zero?(%Literal{literal: literal}), do: negative_zero?(literal)
  def negative_zero?(%{value: zero, uncanonical_lexical: "-" <> _}) when zero == 0, do: true
  def negative_zero?(%{value: %D{sign: -1, coef: 0}}), do: true
  def negative_zero?(_), do: false

  @doc """
  Adds two numeric literals.

  For `xsd:float` or `xsd:double` values, if one of the operands is a zero or a
  finite number and the other is INF or -INF, INF or -INF is returned. If both
  operands are INF, INF is returned. If both operands are -INF, -INF is returned.
  If one of the operands is INF and the other is -INF, NaN is returned.

  If one of the given arguments is not a numeric literal or a value which
  can be coerced into a numeric literal, `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-numeric-add>

  """
  def add(arg1, arg2) do
    arithmetic_operation(:+, arg1, arg2, fn
      :positive_infinity, :negative_infinity, _ -> :nan
      :negative_infinity, :positive_infinity, _ -> :nan
      :positive_infinity, _, _ -> :positive_infinity
      _, :positive_infinity, _ -> :positive_infinity
      :negative_infinity, _, _ -> :negative_infinity
      _, :negative_infinity, _ -> :negative_infinity
      %D{} = arg1, %D{} = arg2, _ -> D.add(arg1, arg2)
      arg1, arg2, _ -> arg1 + arg2
    end)
  end

  @doc """
  Subtracts two numeric literals.

  For `xsd:float` or `xsd:double` values, if one of the operands is a zero or a
  finite number and the other is INF or -INF, an infinity of the appropriate sign
  is returned. If both operands are INF or -INF, NaN is returned. If one of the
  operands is INF and the other is -INF, an infinity of the appropriate sign is
  returned.

  If one of the given arguments is not a numeric literal or a value which
  can be coerced into a numeric literal, `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-numeric-subtract>

  """
  def subtract(arg1, arg2) do
    arithmetic_operation(:-, arg1, arg2, fn
      :positive_infinity, :positive_infinity, _ -> :nan
      :negative_infinity, :negative_infinity, _ -> :nan
      :positive_infinity, :negative_infinity, _ -> :positive_infinity
      :negative_infinity, :positive_infinity, _ -> :negative_infinity
      :positive_infinity, _, _ -> :positive_infinity
      _, :positive_infinity, _ -> :negative_infinity
      :negative_infinity, _, _ -> :negative_infinity
      _, :negative_infinity, _ -> :positive_infinity
      %D{} = arg1, %D{} = arg2, _ -> D.sub(arg1, arg2)
      arg1, arg2, _ -> arg1 - arg2
    end)
  end

  @doc """
  Multiplies two numeric literals.

  For `xsd:float` or `xsd:double` values, if one of the operands is a zero and
  the other is an infinity, NaN is returned. If one of the operands is a non-zero
  number and the other is an infinity, an infinity with the appropriate sign is
  returned.

  If one of the given arguments is not a numeric literal or a value which
  can be coerced into a numeric literal, `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-numeric-multiply>

  """
  def multiply(arg1, arg2) do
    arithmetic_operation(:*, arg1, arg2, fn
      :positive_infinity, :negative_infinity, _ -> :nan
      :negative_infinity, :positive_infinity, _ -> :nan
      inf, zero, _ when inf in [:positive_infinity, :negative_infinity] and zero == 0 -> :nan
      zero, inf, _ when inf in [:positive_infinity, :negative_infinity] and zero == 0 -> :nan
      :positive_infinity, number, _ when number < 0 -> :negative_infinity
      number, :positive_infinity, _ when number < 0 -> :negative_infinity
      :positive_infinity, _, _ -> :positive_infinity
      _, :positive_infinity, _ -> :positive_infinity
      :negative_infinity, number, _ when number < 0 -> :positive_infinity
      number, :negative_infinity, _ when number < 0 -> :positive_infinity
      :negative_infinity, _, _ -> :negative_infinity
      _, :negative_infinity, _ -> :negative_infinity
      %D{} = arg1, %D{} = arg2, _ -> D.mult(arg1, arg2)
      arg1, arg2, _ -> arg1 * arg2
    end)
  end

  @doc """
  Divides two numeric literals.

  For `xsd:float` and `xsd:double` operands, floating point division is performed
  as specified in [IEEE 754-2008]. A positive number divided by positive zero
  returns INF. A negative number divided by positive zero returns -INF. Division
  by negative zero returns -INF and INF, respectively. Positive or negative zero
  divided by positive or negative zero returns NaN. Also, INF or -INF divided by
  INF or -INF returns NaN.

  If one of the given arguments is not a numeric literal or a value which
  can be coerced into a numeric literal, `nil` is returned.

  `nil` is also returned for `xsd:decimal` and `xsd:integer` operands, if the
  divisor is (positive or negative) zero.

  see <http://www.w3.org/TR/xpath-functions/#func-numeric-divide>

  """
  def divide(arg1, arg2) do
    negative_zero = negative_zero?(arg2)

    arithmetic_operation(:/, arg1, arg2, fn
      inf1, inf2, _
      when inf1 in [:positive_infinity, :negative_infinity] and
             inf2 in [:positive_infinity, :negative_infinity] ->
        :nan

      %D{} = arg1, %D{coef: coef} = arg2, _ ->
        unless coef == 0, do: D.div(arg1, arg2)

      arg1, arg2, result_type ->
        if zero_value?(arg2) do
          cond do
            result_type not in [XSD.Double, XSD.Float] -> nil
            zero_value?(arg1) -> :nan
            negative_zero and arg1 < 0 -> :positive_infinity
            negative_zero -> :negative_infinity
            arg1 < 0 -> :negative_infinity
            true -> :positive_infinity
          end
        else
          arg1 / arg2
        end
    end)
  end

  @doc """
  Returns the absolute value of a numeric literal.

  If the given argument is not a numeric literal or a value which
  can be coerced into a numeric literal, `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-abs>

  """
  def abs(literal)

  def abs(%Literal{literal: literal}), do: abs(literal)
  def abs(nil), do: nil

  def abs(value) do
    cond do
      datatype?(value) ->
        if Literal.Datatype.valid?(value) do
          %datatype{} = value

          case value.value do
            :nan ->
              literal(value)

            :positive_infinity ->
              literal(value)

            :negative_infinity ->
              datatype.base_primitive().new(:positive_infinity)

            %D{} = value ->
              value
              |> D.abs()
              |> datatype.base_primitive().new()

            value ->
              target_datatype =
                if XSD.Float.datatype?(datatype), do: XSD.Float, else: datatype.base_primitive()

              value
              |> Kernel.abs()
              |> target_datatype.new()
          end
        end

      # non-numeric datatypes
      Literal.datatype?(value) ->
        nil

      true ->
        value
        |> Literal.coerce()
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

  If the given argument is not a numeric literal or a value which
  can be coerced into a numeric literal, `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-round>

  """
  def round(literal, precision \\ 0)

  def round(%Literal{literal: literal}, precision), do: round(literal, precision)
  def round(nil, _), do: nil

  def round(value, precision) do
    cond do
      datatype?(value) ->
        if Literal.Datatype.valid?(value) do
          %datatype{value: literal_value} = value

          cond do
            XSD.Integer.datatype?(datatype) ->
              if precision < 0 do
                literal_value
                |> new_decimal()
                |> xpath_round(precision)
                |> D.to_integer()
                |> XSD.Integer.new()
              else
                literal(value)
              end

            XSD.Decimal.datatype?(datatype) ->
              literal_value
              |> xpath_round(precision)
              |> to_string()
              |> XSD.Decimal.new()

            (float_datatype = XSD.Float.datatype?(datatype)) or
                XSD.Double.datatype?(datatype) ->
              if literal_value in ~w[nan positive_infinity negative_infinity]a do
                literal(value)
              else
                target_datatype = if float_datatype, do: XSD.Float, else: XSD.Double

                literal_value
                |> new_decimal()
                |> xpath_round(precision)
                |> D.to_float()
                |> target_datatype.new()
              end
          end
        end

      # non-numeric datatypes
      Literal.datatype?(value) ->
        nil

      true ->
        value
        |> Literal.coerce()
        |> round(precision)
    end
  end

  defp xpath_round(%D{sign: -1} = decimal, precision),
    do: D.round(decimal, precision, :half_down)

  defp xpath_round(decimal, precision),
    do: D.round(decimal, precision)

  @doc """
  Rounds a numeric literal upwards to a whole number literal.

  If the given argument is not a numeric literal or a value which
  can be coerced into a numeric literal, `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-ceil>

  """
  def ceil(literal)

  def ceil(%Literal{literal: literal}), do: ceil(literal)
  def ceil(nil), do: nil

  def ceil(value) do
    cond do
      datatype?(value) ->
        if Literal.Datatype.valid?(value) do
          %datatype{value: literal_value} = value

          cond do
            XSD.Integer.datatype?(datatype) ->
              literal(value)

            XSD.Decimal.datatype?(datatype) ->
              literal_value
              |> D.round(0, if(literal_value.sign == -1, do: :down, else: :up))
              |> D.to_string()
              |> XSD.Decimal.new()

            (float_datatype = XSD.Float.datatype?(datatype)) or
                XSD.Double.datatype?(datatype) ->
              if literal_value in ~w[nan positive_infinity negative_infinity]a do
                literal(value)
              else
                target_datatype = if float_datatype, do: XSD.Float, else: XSD.Double

                literal_value
                |> Float.ceil()
                |> trunc()
                |> to_string()
                |> target_datatype.new()
              end
          end
        end

      # non-numeric datatypes
      Literal.datatype?(value) ->
        nil

      true ->
        value
        |> Literal.coerce()
        |> ceil()
    end
  end

  @doc """
  Rounds a numeric literal downwards to a whole number literal.

  If the given argument is not a numeric literal or a value which
  can be coerced into a numeric literal, `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-floor>

  """
  def floor(literal)

  def floor(%Literal{literal: literal}), do: floor(literal)
  def floor(nil), do: nil

  def floor(value) do
    cond do
      datatype?(value) ->
        if Literal.Datatype.valid?(value) do
          %datatype{value: literal_value} = value

          cond do
            XSD.Integer.datatype?(datatype) ->
              literal(value)

            XSD.Decimal.datatype?(datatype) ->
              literal_value
              |> D.round(0, if(literal_value.sign == -1, do: :up, else: :down))
              |> D.to_string()
              |> XSD.Decimal.new()

            (float_datatype = XSD.Float.datatype?(datatype)) or
                XSD.Double.datatype?(datatype) ->
              if literal_value in ~w[nan positive_infinity negative_infinity]a do
                literal(value)
              else
                target_datatype = if float_datatype, do: XSD.Float, else: XSD.Double

                literal_value
                |> Float.floor()
                |> trunc()
                |> to_string()
                |> target_datatype.new()
              end
          end
        end

      # non-numeric datatypes
      Literal.datatype?(value) ->
        nil

      true ->
        value
        |> Literal.coerce()
        |> floor()
    end
  end

  defp arithmetic_operation(op, %Literal{literal: literal1}, literal2, fun),
    do: arithmetic_operation(op, literal1, literal2, fun)

  defp arithmetic_operation(op, literal1, %Literal{literal: literal2}, fun),
    do: arithmetic_operation(op, literal1, literal2, fun)

  defp arithmetic_operation(op, %datatype1{} = literal1, %datatype2{} = literal2, fun) do
    if datatype?(datatype1) and datatype?(datatype2) and
         Literal.Datatype.valid?(literal1) and Literal.Datatype.valid?(literal2) do
      result_type = result_type(op, datatype1, datatype2)
      {arg1, arg2} = type_conversion(literal1, literal2, result_type)
      result = fun.(arg1.value, arg2.value, result_type)
      unless is_nil(result), do: result_type.new(result)
    end
  end

  defp arithmetic_operation(op, left, right, fun) do
    cond do
      is_nil(left) -> nil
      is_nil(right) -> nil
      not Literal.datatype?(left) -> arithmetic_operation(op, Literal.coerce(left), right, fun)
      not Literal.datatype?(right) -> arithmetic_operation(op, left, Literal.coerce(right), fun)
      true -> false
    end
  end

  defp type_conversion(left, right, XSD.Decimal) do
    {
      if XSD.Decimal.datatype?(left) do
        left
      else
        XSD.Decimal.new(left.value).literal
      end,
      if XSD.Decimal.datatype?(right) do
        right
      else
        XSD.Decimal.new(right.value).literal
      end
    }
  end

  defp type_conversion(left, right, datatype) when datatype in [XSD.Double, XSD.Float] do
    {
      if XSD.Decimal.datatype?(left) do
        (left.value |> D.to_float() |> XSD.Double.new()).literal
      else
        left
      end,
      if XSD.Decimal.datatype?(right) do
        (right.value |> D.to_float() |> XSD.Double.new()).literal
      else
        right
      end
    }
  end

  defp type_conversion(left, right, _), do: {left, right}

  @doc false
  def result_type(op, left, right),
    do: do_result_type(op, base_primitive(left), base_primitive(right))

  defp do_result_type(_, XSD.Double, _), do: XSD.Double
  defp do_result_type(_, _, XSD.Double), do: XSD.Double
  defp do_result_type(_, XSD.Float, _), do: XSD.Float
  defp do_result_type(_, _, XSD.Float), do: XSD.Float
  defp do_result_type(_, XSD.Decimal, _), do: XSD.Decimal
  defp do_result_type(_, _, XSD.Decimal), do: XSD.Decimal
  defp do_result_type(:/, _, _), do: XSD.Decimal
  defp do_result_type(_, _, _), do: XSD.Integer

  defp base_primitive(datatype) do
    primitive = datatype.base_primitive()

    if primitive == XSD.Double and XSD.Float.datatype?(datatype),
      do: XSD.Float,
      else: primitive
  end

  defp literal(value), do: %Literal{literal: value}
end
