defmodule RDF.Numeric do
  @moduledoc """
  Collection of functions for numeric literals.
  """

  alias RDF.Literal

  import Kernel, except: [abs: 1, floor: 1, ceil: 1, round: 1]

  @datatypes MapSet.new(XSD.Numeric.datatypes(), &RDF.Literal.Datatype.Registry.rdf_datatype/1)

  @doc """
  The set of all numeric datatypes.
  """
  def datatypes(), do: @datatypes

  @doc """
  Returns if a given datatype is a numeric datatype.
  """
  def datatype?(datatype), do: datatype in @datatypes

  @doc """
  Returns if a given literal has a numeric datatype.
  """
  @spec literal?(Literal.t | any) :: boolean
  def literal?(%Literal{literal: %datatype{}}), do: datatype?(datatype)
  def literal?(_),                              do: false


  def zero?(%Literal{literal: literal}), do: zero?(literal)
  def zero?(literal), do: XSD.Numeric.zero?(literal)

  def negative_zero?(%Literal{literal: literal}), do: negative_zero?(literal)
  def negative_zero?(literal), do: XSD.Numeric.negative_zero?(literal)

  @doc """
  Adds two numeric literals.

  For `xsd:float` or `xsd:double` values, if one of the operands is a zero or a
  finite number and the other is INF or -INF, INF or -INF is returned. If both
  operands are INF, INF is returned. If both operands are -INF, -INF is returned.
  If one of the operands is INF and the other is -INF, NaN is returned.

  If one of the given arguments is not a numeric literal, `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-numeric-add>
  """
  def add(left, right)
  def add(left, %Literal{literal: right}), do: add(left, right)
  def add(%Literal{literal: left}, right), do: add(left, right)
  def add(left, right) do
    if result = XSD.Numeric.add(left, right) do
      Literal.new(result)
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
  def subtract(left, right)
  def subtract(left, %Literal{literal: right}), do: subtract(left, right)
  def subtract(%Literal{literal: left}, right), do: subtract(left, right)
  def subtract(left, right) do
    if result = XSD.Numeric.subtract(left, right) do
      Literal.new(result)
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
  def multiply(left, right)
  def multiply(left, %Literal{literal: right}), do: multiply(left, right)
  def multiply(%Literal{literal: left}, right), do: multiply(left, right)
  def multiply(left, right) do
    if result = XSD.Numeric.multiply(left, right) do
      Literal.new(result)
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
  def divide(left, right)
  def divide(left, %Literal{literal: right}), do: divide(left, right)
  def divide(%Literal{literal: left}, right), do: divide(left, right)
  def divide(left, right) do
    if result = XSD.Numeric.divide(left, right) do
      Literal.new(result)
    end
  end

  @doc """
  Returns the absolute value of a numeric literal.

  If the argument is not a valid numeric literal `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-abs>
  """
  def abs(numeric)
  def abs(%Literal{literal: numeric}), do: abs(numeric)
  def abs(numeric) do
    if result = XSD.Numeric.abs(numeric) do
      Literal.new(result)
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
  def round(numeric, precision \\ 0)
  def round(%Literal{literal: numeric}, precision), do: round(numeric, precision)
  def round(numeric, precision) do
    if result = XSD.Numeric.round(numeric, precision) do
      Literal.new(result)
    end
  end

  @doc """
  Rounds a numeric literal upwards to a whole number literal.

  If the argument is not a valid numeric literal `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-ceil>
  """
  def ceil(numeric)
  def ceil(%Literal{literal: numeric}), do: ceil(numeric)
  def ceil(numeric) do
    if result = XSD.Numeric.ceil(numeric) do
      Literal.new(result)
    end
  end

  @doc """
  Rounds a numeric literal downwards to a whole number literal.

  If the argument is not a valid numeric literal `nil` is returned.

  see <http://www.w3.org/TR/xpath-functions/#func-floor>
  """
  def floor(numeric)
  def floor(%Literal{literal: numeric}), do: floor(numeric)
  def floor(numeric) do
    if result = XSD.Numeric.floor(numeric) do
      Literal.new(result)
    end
  end
end
