defmodule RDF.XSD.NumericTest do
  use ExUnit.Case

  alias RDF.XSD
  alias XSD.Numeric
  alias RDF.TestDatatypes.{Age, DecimalUnitInterval, DoubleUnitInterval, FloatUnitInterval}

  alias Decimal, as: D

  @positive_infinity XSD.double(:positive_infinity)
  @negative_infinity XSD.double(:negative_infinity)
  @nan XSD.double(:nan)

  @negative_zeros ~w[
    -0
    -000
    -0.0
    -0.00000
  ]

  test "negative_zero?/1" do
    Enum.each(@negative_zeros, fn negative_zero ->
      assert Numeric.negative_zero?(XSD.double(negative_zero))
      assert Numeric.negative_zero?(XSD.float(negative_zero))
      assert Numeric.negative_zero?(XSD.decimal(negative_zero))
    end)

    refute Numeric.negative_zero?(XSD.double("-0.00001"))
    refute Numeric.negative_zero?(XSD.float("-0.00001"))
    refute Numeric.negative_zero?(XSD.decimal("-0.00001"))
  end

  test "zero?/1" do
    assert Numeric.zero?(XSD.integer(0))
    assert Numeric.zero?(XSD.integer("0"))

    ~w[
      0
      000
      0.0
      00.00
    ]
    |> Enum.each(fn positive_zero ->
      assert Numeric.zero?(XSD.double(positive_zero))
      assert Numeric.zero?(XSD.float(positive_zero))
      assert Numeric.zero?(XSD.decimal(positive_zero))
    end)

    Enum.each(@negative_zeros, fn negative_zero ->
      assert Numeric.zero?(XSD.double(negative_zero))
      assert Numeric.zero?(XSD.float(negative_zero))
      assert Numeric.zero?(XSD.decimal(negative_zero))
    end)

    refute Numeric.zero?(XSD.double("-0.00001"))
    refute Numeric.zero?(XSD.float("-0.00001"))
    refute Numeric.zero?(XSD.decimal("-0.00001"))
  end

  describe "add/2" do
    test "xsd:integer literal + xsd:integer literal" do
      assert Numeric.add(XSD.integer(1), XSD.integer(2)) == XSD.integer(3)
      assert Numeric.add(XSD.integer(1), XSD.byte(2)) == XSD.integer(3)
      assert Numeric.add(XSD.byte(1), XSD.integer(2)) == XSD.integer(3)
      assert Numeric.add(XSD.integer(1), Age.new(2)) == XSD.integer(3)
    end

    test "xsd:decimal literal + xsd:integer literal" do
      assert Numeric.add(XSD.decimal(1.1), XSD.integer(2)) == XSD.decimal(3.1)
      assert Numeric.add(XSD.decimal(1.1), XSD.positiveInteger(2)) == XSD.decimal(3.1)
      assert Numeric.add(XSD.decimal(1.1), Age.new(2)) == XSD.decimal(3.1)
      assert Numeric.add(XSD.positiveInteger(2), XSD.decimal(1.1)) == XSD.decimal(3.1)
      assert Numeric.add(XSD.decimal(1.5), Age.new(3)) == XSD.decimal(4.5)
      assert Numeric.add(DecimalUnitInterval.new(0.5), Age.new(3)) == XSD.decimal(3.5)
    end

    test "xsd:double literal + xsd:integer literal" do
      assert result = %RDF.Literal{literal: %XSD.Double{}} = Numeric.add(XSD.double(1.1), XSD.integer(2))
      assert_in_delta RDF.Literal.value(result),
                      RDF.Literal.value(XSD.double(3.1)), 0.000000000000001

      assert result = %RDF.Literal{literal: %XSD.Double{}} = Numeric.add(XSD.double(1.1), Age.new(2))
      assert_in_delta RDF.Literal.value(result),
                      RDF.Literal.value(XSD.double(3.1)), 0.000000000000001

      assert result = %RDF.Literal{literal: %XSD.Double{}} = Numeric.add(DoubleUnitInterval.new(0.5), Age.new(2))
      assert_in_delta RDF.Literal.value(result),
                      RDF.Literal.value(XSD.double(2.5)), 0.000000000000001
    end

    test "xsd:decimal literal + xsd:double literal" do
      assert result = %RDF.Literal{literal: %XSD.Double{}} = Numeric.add(XSD.decimal(1.1), XSD.double(2.2))
      assert_in_delta RDF.Literal.value(result),
                      RDF.Literal.value(XSD.double(3.3)), 0.000000000000001

      assert result = %RDF.Literal{literal: %XSD.Double{}} =
               Numeric.add(DecimalUnitInterval.new(0.5), DoubleUnitInterval.new(0.5))
      assert_in_delta RDF.Literal.value(result),
                      RDF.Literal.value(XSD.double(1.0)), 0.000000000000001
    end

    test "xsd:float literal + xsd:integer literal" do
      assert result = %RDF.Literal{literal: %XSD.Float{}} = Numeric.add(XSD.float(1.1), XSD.integer(2))
      assert_in_delta RDF.Literal.value(result),
                      RDF.Literal.value(XSD.float(3.1)), 0.000000000000001
      assert result = %RDF.Literal{literal: %XSD.Float{}} =
               Numeric.add(Age.new(42), FloatUnitInterval.new(0.5))
      assert_in_delta RDF.Literal.value(result),
                      RDF.Literal.value(XSD.float(42.5)), 0.000000000000001
    end

    test "xsd:decimal literal + xsd:float literal" do
      assert result = %RDF.Literal{literal: %XSD.Float{}} = Numeric.add(XSD.decimal(1.1), XSD.float(2.2))
      assert_in_delta RDF.Literal.value(result),
                      RDF.Literal.value(XSD.float(3.3)), 0.000000000000001

      assert result = %RDF.Literal{literal: %XSD.Float{}} =
               Numeric.add(DecimalUnitInterval.new(0.5), FloatUnitInterval.new(0.5))
      assert_in_delta RDF.Literal.value(result),
                      RDF.Literal.value(XSD.float(1.0)), 0.000000000000001
    end

    test "if one of the operands is a zero or a finite number and the other is INF or -INF, INF or -INF is returned" do
      assert Numeric.add(@positive_infinity, XSD.double(0)) == @positive_infinity
      assert Numeric.add(@positive_infinity, XSD.double(3.14)) == @positive_infinity
      assert Numeric.add(XSD.double(0), @positive_infinity) == @positive_infinity
      assert Numeric.add(XSD.double(3.14), @positive_infinity) == @positive_infinity

      assert Numeric.add(@negative_infinity, XSD.double(0)) == @negative_infinity
      assert Numeric.add(@negative_infinity, XSD.double(3.14)) == @negative_infinity
      assert Numeric.add(XSD.double(0), @negative_infinity) == @negative_infinity
      assert Numeric.add(XSD.double(3.14), @negative_infinity) == @negative_infinity
      assert Numeric.add(@negative_infinity, Age.new(1)) == @negative_infinity
    end

    test "if both operands are INF, INF is returned" do
      assert Numeric.add(@positive_infinity, @positive_infinity) ==
               @positive_infinity
    end

    test "if both operands are -INF, -INF is returned" do
      assert Numeric.add(@negative_infinity, @negative_infinity) ==
               @negative_infinity
    end

    test "if one of the operands is INF and the other is -INF, NaN is returned" do
      assert Numeric.add(@positive_infinity, @negative_infinity) == @nan
      assert Numeric.add(@negative_infinity, @positive_infinity) == @nan
    end

    test "coercion" do
      assert Numeric.add(1, 2) == XSD.integer(3)
      assert Numeric.add(3.14, 42) == XSD.double(45.14)
      assert XSD.decimal(3.14) |> Numeric.add(42) == XSD.decimal(45.14)
      assert Numeric.add(42, XSD.decimal(3.14)) == XSD.decimal(45.14)
      assert Numeric.add(42, :foo) == nil
      assert Numeric.add(:foo, 42) == nil
      assert Numeric.add(:foo, :bar) == nil
    end

    test "with invalid numeric literals" do
      refute Numeric.add(XSD.integer("foo"), XSD.integer("bar"))
      refute Numeric.add(XSD.integer("foo"), XSD.integer(1))
      refute Numeric.add(XSD.integer(1), XSD.integer("foo"))
      refute Numeric.add(XSD.integer(1), XSD.byte(300))
      refute Numeric.add(XSD.integer(1), Age.new(200))
    end
  end

  describe "subtract/2" do
    test "xsd:integer literal - xsd:integer literal" do
      assert Numeric.subtract(XSD.integer(3), XSD.integer(2)) == XSD.integer(1)
      assert Numeric.subtract(XSD.integer(3), XSD.short(2)) == XSD.integer(1)
      assert Numeric.subtract(XSD.integer(3), Age.new(2)) == XSD.integer(1)
    end

    test "xsd:decimal literal - xsd:integer literal" do
      assert Numeric.subtract(XSD.decimal(3.3), XSD.integer(2)) == XSD.decimal(1.3)
      assert Numeric.subtract(XSD.decimal(3.3), XSD.positiveInteger(2)) == XSD.decimal(1.3)
    end

    test "xsd:double literal - xsd:integer literal" do
      assert result = %RDF.Literal{literal: %XSD.Double{}} = Numeric.subtract(XSD.double(3.3), XSD.integer(2))
      assert_in_delta RDF.Literal.value(result),
                      RDF.Literal.value(XSD.double(1.3)), 0.000000000000001
    end

    test "xsd:decimal literal - xsd:double literal" do
      assert result = %RDF.Literal{literal: %XSD.Double{}} = Numeric.subtract(XSD.decimal(3.3), XSD.double(2.2))
      assert_in_delta RDF.Literal.value(result),
                      RDF.Literal.value(XSD.double(1.1)), 0.000000000000001
    end

    test "if one of the operands is a zero or a finite number and the other is INF or -INF, an infinity of the appropriate sign is returned" do
      assert Numeric.subtract(@positive_infinity, XSD.double(0)) == @positive_infinity
      assert Numeric.subtract(@positive_infinity, XSD.double(3.14)) == @positive_infinity
      assert Numeric.subtract(XSD.double(0), @positive_infinity) == @negative_infinity
      assert Numeric.subtract(XSD.double(3.14), @positive_infinity) == @negative_infinity

      assert Numeric.subtract(@negative_infinity, XSD.double(0)) == @negative_infinity
      assert Numeric.subtract(@negative_infinity, XSD.double(3.14)) == @negative_infinity
      assert Numeric.subtract(XSD.double(0), @negative_infinity) == @positive_infinity
      assert Numeric.subtract(XSD.double(3.14), @negative_infinity) == @positive_infinity
    end

    test "if both operands are INF or -INF, NaN is returned" do
      assert Numeric.subtract(@positive_infinity, @positive_infinity) == XSD.double(:nan)
      assert Numeric.subtract(@negative_infinity, @negative_infinity) == XSD.double(:nan)
    end

    test "if one of the operands is INF and the other is -INF, an infinity of the appropriate sign is returned" do
      assert Numeric.subtract(@positive_infinity, @negative_infinity) == @positive_infinity
      assert Numeric.subtract(@negative_infinity, @positive_infinity) == @negative_infinity
    end

    test "coercion" do
      assert Numeric.subtract(2, 1) == XSD.integer(1)
      assert Numeric.subtract(42, 3.14) == XSD.double(38.86)
      assert XSD.decimal(3.14) |> Numeric.subtract(42) == XSD.decimal(-38.86)
      assert Numeric.subtract(42, XSD.decimal(3.14)) == XSD.decimal(38.86)
    end
  end

  describe "multiply/2" do
    test "xsd:integer literal * xsd:integer literal" do
      assert Numeric.multiply(XSD.integer(2), XSD.integer(3)) == XSD.integer(6)
      assert Numeric.multiply(Age.new(2), XSD.integer(3)) == XSD.integer(6)
    end

    test "xsd:decimal literal * xsd:integer literal" do
      assert Numeric.multiply(XSD.decimal(1.5), XSD.integer(3)) == XSD.decimal(4.5)
    end

    test "xsd:double literal * xsd:integer literal" do
      assert result = %RDF.Literal{literal: %XSD.Double{}} = Numeric.multiply(XSD.double(1.5), XSD.integer(3))
      assert_in_delta RDF.Literal.value(result),
                      RDF.Literal.value(XSD.double(4.5)), 0.000000000000001
    end

    test "xsd:decimal literal * xsd:double literal" do
      assert result = %RDF.Literal{literal: %XSD.Double{}} = Numeric.multiply(XSD.decimal(0.5), XSD.double(2.5))
      assert_in_delta RDF.Literal.value(result),
                      RDF.Literal.value(XSD.double(1.25)), 0.000000000000001
    end

    test "if one of the operands is a zero and the other is an infinity, NaN is returned" do
      assert Numeric.multiply(@positive_infinity, XSD.double(0.0)) == @nan
      assert Numeric.multiply(XSD.integer(0), @positive_infinity) == @nan
      assert Numeric.multiply(XSD.decimal(0), @positive_infinity) == @nan

      assert Numeric.multiply(@negative_infinity, XSD.double(0)) == @nan
      assert Numeric.multiply(XSD.integer(0), @negative_infinity) == @nan
      assert Numeric.multiply(XSD.decimal(0.0), @negative_infinity) == @nan
    end

    test "if one of the operands is a non-zero number and the other is an infinity, an infinity with the appropriate sign is returned" do
      assert Numeric.multiply(@positive_infinity, XSD.double(3.14)) == @positive_infinity
      assert Numeric.multiply(XSD.double(3.14), @positive_infinity) == @positive_infinity
      assert Numeric.multiply(@positive_infinity, XSD.double(-3.14)) == @negative_infinity
      assert Numeric.multiply(XSD.double(-3.14), @positive_infinity) == @negative_infinity

      assert Numeric.multiply(@negative_infinity, XSD.double(3.14)) == @negative_infinity
      assert Numeric.multiply(XSD.double(3.14), @negative_infinity) == @negative_infinity
      assert Numeric.multiply(@negative_infinity, XSD.double(-3.14)) == @positive_infinity
      assert Numeric.multiply(XSD.double(-3.14), @negative_infinity) == @positive_infinity
    end

    # The following assertions are not part of the spec.

    test "if both operands are INF, INF is returned" do
      assert Numeric.multiply(@positive_infinity, @positive_infinity) == @positive_infinity
    end

    test "if both operands are -INF, -INF is returned" do
      assert Numeric.multiply(@negative_infinity, @negative_infinity) == @negative_infinity
    end

    test "if one of the operands is INF and the other is -INF, NaN is returned" do
      assert Numeric.multiply(@positive_infinity, @negative_infinity) == XSD.double(:nan)
      assert Numeric.multiply(@negative_infinity, @positive_infinity) == XSD.double(:nan)
    end

    test "coercion" do
      assert Numeric.multiply(1, 2) == XSD.integer(2)
      assert Numeric.multiply(2, 1.5) == XSD.double(3.0)
      assert XSD.decimal(1.5) |> Numeric.multiply(2) == XSD.decimal(3.0)
      assert Numeric.multiply(2, XSD.decimal(1.5)) == XSD.decimal(3.0)
    end
  end

  describe "divide/2" do
    test "xsd:integer literal / xsd:integer literal" do
      assert Numeric.divide(XSD.integer(4), XSD.integer(2)) == XSD.decimal(2.0)
      assert Numeric.divide(XSD.integer(4), Age.new(2)) == XSD.decimal(2.0)
      assert Numeric.divide(Age.new(4), Age.new(2)) == XSD.decimal(2.0)
    end

    test "xsd:decimal literal / xsd:integer literal" do
      assert Numeric.divide(XSD.decimal(4), XSD.integer(2)) == XSD.decimal(2.0)
    end

    test "xsd:double literal / xsd:integer literal" do
      assert result = %RDF.Literal{literal: %XSD.Double{}} = Numeric.divide(XSD.double(4), XSD.integer(2))
      assert_in_delta RDF.Literal.value(result),
                      RDF.Literal.value(XSD.double(2)), 0.000000000000001
    end

    test "xsd:decimal literal / xsd:double literal" do
      assert result = %RDF.Literal{literal: %XSD.Double{}} = Numeric.divide(XSD.decimal(4), XSD.double(2))
      assert_in_delta RDF.Literal.value(result),
                      RDF.Literal.value(XSD.double(2)), 0.000000000000001
    end

    test "a positive number divided by positive zero returns INF" do
      assert Numeric.divide(XSD.double(1.0), XSD.double(0.0)) == @positive_infinity
      assert Numeric.divide(XSD.double(1.0), XSD.decimal(0.0)) == @positive_infinity
      assert Numeric.divide(XSD.double(1.0), XSD.integer(0)) == @positive_infinity
      assert Numeric.divide(XSD.decimal(1.0), XSD.double(0.0)) == @positive_infinity
      assert Numeric.divide(XSD.integer(1), XSD.double(0.0)) == @positive_infinity
    end

    test "a negative number divided by positive zero returns -INF" do
      assert Numeric.divide(XSD.double(-1.0), XSD.double(0.0)) == @negative_infinity
      assert Numeric.divide(XSD.double(-1.0), XSD.decimal(0.0)) == @negative_infinity
      assert Numeric.divide(XSD.double(-1.0), XSD.integer(0)) == @negative_infinity
      assert Numeric.divide(XSD.decimal(-1.0), XSD.double(0.0)) == @negative_infinity
      assert Numeric.divide(XSD.integer(-1), XSD.double(0.0)) == @negative_infinity
    end

    test "a positive number divided by negative zero returns -INF" do
      assert Numeric.divide(XSD.double(1.0), XSD.double("-0.0")) == @negative_infinity
      assert Numeric.divide(XSD.double(1.0), XSD.decimal("-0.0")) == @negative_infinity
      assert Numeric.divide(XSD.decimal(1.0), XSD.double("-0.0")) == @negative_infinity
      assert Numeric.divide(XSD.integer(1), XSD.double("-0.0")) == @negative_infinity
    end

    test "a negative number divided by negative zero returns INF" do
      assert Numeric.divide(XSD.double(-1.0), XSD.double("-0.0")) == @positive_infinity
      assert Numeric.divide(XSD.double(-1.0), XSD.decimal("-0.0")) == @positive_infinity
      assert Numeric.divide(XSD.decimal(-1.0), XSD.double("-0.0")) == @positive_infinity
      assert Numeric.divide(XSD.integer(-1), XSD.double("-0.0")) == @positive_infinity
    end

    test "nil is returned for xs:decimal and xs:integer operands, if the divisor is (positive or negative) zero" do
      assert Numeric.divide(XSD.decimal(1.0), XSD.decimal(0.0)) == nil
      assert Numeric.divide(XSD.decimal(1.0), XSD.integer(0)) == nil
      assert Numeric.divide(XSD.decimal(-1.0), XSD.decimal(0.0)) == nil
      assert Numeric.divide(XSD.decimal(-1.0), XSD.integer(0)) == nil
      assert Numeric.divide(XSD.integer(1), XSD.integer(0)) == nil
      assert Numeric.divide(XSD.integer(1), XSD.decimal(0.0)) == nil
      assert Numeric.divide(XSD.integer(-1), XSD.integer(0)) == nil
      assert Numeric.divide(XSD.integer(-1), XSD.decimal(0.0)) == nil
    end

    test "positive or negative zero divided by positive or negative zero returns NaN" do
      assert Numeric.divide(XSD.double("-0.0"), XSD.double(0.0)) == @nan
      assert Numeric.divide(XSD.double("-0.0"), XSD.decimal(0.0)) == @nan
      assert Numeric.divide(XSD.double("-0.0"), XSD.integer(0)) == @nan
      assert Numeric.divide(XSD.decimal("-0.0"), XSD.double(0.0)) == @nan
      assert Numeric.divide(XSD.integer("-0"), XSD.double(0.0)) == @nan

      assert Numeric.divide(XSD.double("0.0"), XSD.double(0.0)) == @nan
      assert Numeric.divide(XSD.double("0.0"), XSD.decimal(0.0)) == @nan
      assert Numeric.divide(XSD.double("0.0"), XSD.integer(0)) == @nan
      assert Numeric.divide(XSD.decimal("0.0"), XSD.double(0.0)) == @nan
      assert Numeric.divide(XSD.integer("0"), XSD.double(0.0)) == @nan

      assert Numeric.divide(XSD.double(0.0), XSD.double("-0.0")) == @nan
      assert Numeric.divide(XSD.decimal(0.0), XSD.double("-0.0")) == @nan
      assert Numeric.divide(XSD.integer(0), XSD.double("-0.0")) == @nan
      assert Numeric.divide(XSD.double(0.0), XSD.decimal("-0.0")) == @nan
      assert Numeric.divide(XSD.double(0.0), XSD.integer("-0")) == @nan

      assert Numeric.divide(XSD.double(0.0), XSD.double("0.0")) == @nan
      assert Numeric.divide(XSD.decimal(0.0), XSD.double("0.0")) == @nan
      assert Numeric.divide(XSD.integer(0), XSD.double("0.0")) == @nan
      assert Numeric.divide(XSD.double(0.0), XSD.decimal("0.0")) == @nan
      assert Numeric.divide(XSD.double(0.0), XSD.integer("0")) == @nan
    end

    test "INF or -INF divided by INF or -INF returns NaN" do
      assert Numeric.divide(@positive_infinity, @positive_infinity) == @nan
      assert Numeric.divide(@negative_infinity, @negative_infinity) == @nan
      assert Numeric.divide(@positive_infinity, @negative_infinity) == @nan
      assert Numeric.divide(@negative_infinity, @positive_infinity) == @nan
    end

    # TODO: What happens when using INF/-INF on division with numbers?

    test "coercion" do
      assert Numeric.divide(4, 2) == XSD.decimal(2.0)
      assert Numeric.divide(4, 2.0) == XSD.double(2.0)
      assert XSD.decimal(4) |> Numeric.divide(2) == XSD.decimal(2.0)
      assert Numeric.divide(4, XSD.decimal(2.0)) == XSD.decimal(2.0)
      assert Numeric.divide("foo", "bar") == nil
      assert Numeric.divide(4, "bar") == nil
      assert Numeric.divide("foo", 2) == nil
      assert Numeric.divide(42, :bar) == nil
      assert Numeric.divide(:foo, 42) == nil
      assert Numeric.divide(:foo, :bar) == nil
    end
  end

  describe "abs/1" do
    test "with xsd:integer" do
      assert XSD.integer(42) |> Numeric.abs() == XSD.integer(42)
      assert XSD.integer(-42) |> Numeric.abs() == XSD.integer(42)
    end

    test "with xsd:double" do
      assert XSD.double(3.14) |> Numeric.abs() == XSD.double(3.14)
      assert XSD.double(-3.14) |> Numeric.abs() == XSD.double(3.14)
      assert XSD.double("INF") |> Numeric.abs() == XSD.double("INF")
      assert XSD.double("-INF") |> Numeric.abs() == XSD.double("INF")
      assert XSD.double("NAN") |> Numeric.abs() == XSD.double("NAN")
    end

    test "with xsd:decimal" do
      assert XSD.decimal(3.14) |> Numeric.abs() == XSD.decimal(3.14)
      assert XSD.decimal(-3.14) |> Numeric.abs() == XSD.decimal(3.14)
    end

    test "with derived numerics" do
      assert XSD.byte(-42) |> Numeric.abs() == XSD.integer(42)
      assert XSD.byte("-42") |> Numeric.abs() == XSD.integer(42)
      assert XSD.non_positive_integer(-42) |> Numeric.abs() == XSD.integer(42)
      assert DecimalUnitInterval.new(0.14) |> Numeric.abs() == XSD.decimal(0.14)
      assert DoubleUnitInterval.new(0.14) |> Numeric.abs() == XSD.double(0.14)
      assert FloatUnitInterval.new(0.14) |> Numeric.abs() == XSD.float(0.14)
    end

    test "with invalid numeric literals" do
      assert XSD.integer("-3.14") |> Numeric.abs() == nil
      assert XSD.double("foo") |> Numeric.abs() == nil
      assert XSD.decimal("foo") |> Numeric.abs() == nil
    end

    test "coercion" do
      assert Numeric.abs(42) == XSD.integer(42)
      assert Numeric.abs(-42) == XSD.integer(42)
      assert Numeric.abs(-3.14) == XSD.double(3.14)
      assert Numeric.abs(D.from_float(-3.14)) == XSD.decimal(3.14)
      assert Numeric.abs("foo") == nil
      assert Numeric.abs(:foo) == nil
    end
  end

  describe "round/1" do
    test "with xsd:integer" do
      assert XSD.integer(42) |> Numeric.round() == XSD.integer(42)
      assert XSD.integer(-42) |> Numeric.round() == XSD.integer(-42)
    end

    test "with xsd:double" do
      assert XSD.double(3.14) |> Numeric.round() == XSD.double(3.0)
      assert XSD.double(-3.14) |> Numeric.round() == XSD.double(-3.0)
      assert XSD.double(-2.5) |> Numeric.round() == XSD.double(-2.0)

      assert XSD.double("INF") |> Numeric.round() == XSD.double("INF")
      assert XSD.double("-INF") |> Numeric.round() == XSD.double("-INF")
      assert XSD.double("NAN") |> Numeric.round() == XSD.double("NAN")
    end

    test "with xsd:decimal" do
      assert XSD.decimal(2.5) |> Numeric.round() == XSD.decimal("3")
      assert XSD.decimal(2.4999) |> Numeric.round() == XSD.decimal("2")
      assert XSD.decimal(-2.5) |> Numeric.round() == XSD.decimal("-2")
    end

    test "with derived numerics" do
      assert XSD.byte(42) |> Numeric.round() == XSD.byte(42)
      assert XSD.non_positive_integer(-42) |> Numeric.round() == XSD.non_positive_integer(-42)
      assert DecimalUnitInterval.new(0.14) |> Numeric.round() == XSD.decimal("0")
      assert DoubleUnitInterval.new(0.14) |> Numeric.round() == XSD.double(0)
      assert FloatUnitInterval.new(0.14) |> Numeric.round() == XSD.float(0)
    end

    test "with invalid numeric literals" do
      assert XSD.integer("-3.14") |> Numeric.round() == nil
      assert XSD.double("foo") |> Numeric.round() == nil
      assert XSD.decimal("foo") |> Numeric.round() == nil
    end

    test "coercion" do
      assert Numeric.round(-42) == XSD.integer(-42)
      assert Numeric.round(-3.14) == XSD.double(-3.0)
      assert Numeric.round(D.from_float(3.14)) == XSD.decimal("3")
      assert Numeric.round("foo") == nil
      assert Numeric.round(:foo) == nil
    end
  end

  describe "round/2" do
    test "with xsd:integer" do
      assert XSD.integer(42) |> Numeric.round(3) == XSD.integer(42)
      assert XSD.integer(8452) |> Numeric.round(-2) == XSD.integer(8500)
      assert XSD.integer(85) |> Numeric.round(-1) == XSD.integer(90)
      assert XSD.integer(-85) |> Numeric.round(-1) == XSD.integer(-80)
    end

    test "with xsd:double" do
      assert XSD.double(3.14) |> Numeric.round(1) == XSD.double(3.1)
      assert XSD.double(3.1415e0) |> Numeric.round(2) == XSD.double(3.14e0)

      assert XSD.double("INF") |> Numeric.round(1) == XSD.double("INF")
      assert XSD.double("-INF") |> Numeric.round(2) == XSD.double("-INF")
      assert XSD.double("NAN") |> Numeric.round(3) == XSD.double("NAN")
    end

    test "with xsd:float" do
      assert XSD.float(3.14) |> Numeric.round(1) == XSD.float(3.1)
      assert XSD.float(3.1415e0) |> Numeric.round(2) == XSD.float(3.14e0)

      assert XSD.float("INF") |> Numeric.round(1) == XSD.float("INF")
      assert XSD.float("-INF") |> Numeric.round(2) == XSD.float("-INF")
      assert XSD.float("NAN") |> Numeric.round(3) == XSD.float("NAN")
    end

    test "with xsd:decimal" do
      assert XSD.decimal(1.125) |> Numeric.round(2) == XSD.decimal("1.13")
      assert XSD.decimal(2.4999) |> Numeric.round(2) == XSD.decimal("2.50")
      assert XSD.decimal(-2.55) |> Numeric.round(1) == XSD.decimal("-2.5")
    end

    test "with derived numerics" do
      assert XSD.byte(42) |> Numeric.round(2) == XSD.byte(42)
      assert XSD.non_positive_integer(-42) |> Numeric.round(2) == XSD.non_positive_integer(-42)
      assert DecimalUnitInterval.new(0.14) |> Numeric.round(1) == XSD.decimal(0.1)
      assert DoubleUnitInterval.new(0.14) |> Numeric.round(1) == XSD.double(0.1)
      assert FloatUnitInterval.new(0.14) |> Numeric.round(1) == XSD.float(0.1)
    end

    test "with invalid numeric literals" do
      assert XSD.integer("-3.14") |> Numeric.round(1) == nil
      assert XSD.double("foo") |> Numeric.round(2) == nil
      assert XSD.decimal("foo") |> Numeric.round(3) == nil
    end

    test "coercion" do
      assert Numeric.round(-42, 1) == XSD.integer(-42)
      assert Numeric.round(-3.14, 1) == XSD.double(-3.1)
      assert Numeric.round(D.from_float(3.14), 1) == XSD.decimal("3.1")
      assert Numeric.round("foo", 1) == nil
      assert Numeric.round(:foo, 1) == nil
    end
  end

  describe "ceil/1" do
    test "with xsd:integer" do
      assert XSD.integer(42) |> Numeric.ceil() == XSD.integer(42)
      assert XSD.integer(-42) |> Numeric.ceil() == XSD.integer(-42)
    end

    test "with xsd:double" do
      assert XSD.double(10.5) |> Numeric.ceil() == XSD.double("11")
      assert XSD.double(-10.5) |> Numeric.ceil() == XSD.double("-10")

      assert XSD.double("INF") |> Numeric.ceil() == XSD.double("INF")
      assert XSD.double("-INF") |> Numeric.ceil() == XSD.double("-INF")
      assert XSD.double("NAN") |> Numeric.ceil() == XSD.double("NAN")
    end

    test "with xsd:float" do
      assert XSD.float(10.5) |> Numeric.ceil() == XSD.float("11")
      assert XSD.float(-10.5) |> Numeric.ceil() == XSD.float("-10")

      assert XSD.float("INF") |> Numeric.ceil() == XSD.float("INF")
      assert XSD.float("-INF") |> Numeric.ceil() == XSD.float("-INF")
      assert XSD.float("NAN") |> Numeric.ceil() == XSD.float("NAN")
    end

    test "with xsd:decimal" do
      assert XSD.decimal(10.5) |> Numeric.ceil() == XSD.decimal("11")
      assert XSD.decimal(-10.5) |> Numeric.ceil() == XSD.decimal("-10")
    end

    test "with derived numerics" do
      assert XSD.byte(42) |> Numeric.ceil() == XSD.byte(42)
      assert XSD.non_positive_integer(-42) |> Numeric.ceil() == XSD.non_positive_integer(-42)
      assert DoubleUnitInterval.new(0.14) |> Numeric.ceil() == XSD.double("1")
      assert DoubleUnitInterval.new(0.4) |> Numeric.ceil() == XSD.double("1")
      assert FloatUnitInterval.new(0.5) |> Numeric.ceil() == XSD.float("1")
    end

    test "with invalid numeric literals" do
      assert XSD.integer("-3.14") |> Numeric.ceil() == nil
      assert XSD.double("foo") |> Numeric.ceil() == nil
      assert XSD.decimal("foo") |> Numeric.ceil() == nil
    end

    test "coercion" do
      assert Numeric.ceil(-42) == XSD.integer(-42)
      assert Numeric.ceil(-3.14) == XSD.double("-3")
      assert Numeric.ceil(D.from_float(3.14)) == XSD.decimal("4")
      assert Numeric.ceil("foo") == nil
      assert Numeric.ceil(:foo) == nil
    end
  end

  describe "floor/1" do
    test "with xsd:integer" do
      assert XSD.integer(42) |> Numeric.floor() == XSD.integer(42)
      assert XSD.integer(-42) |> Numeric.floor() == XSD.integer(-42)
    end

    test "with xsd:double" do
      assert XSD.double(10.5) |> Numeric.floor() == XSD.double("10")
      assert XSD.double(-10.5) |> Numeric.floor() == XSD.double("-11")

      assert XSD.double("INF") |> Numeric.floor() == XSD.double("INF")
      assert XSD.double("-INF") |> Numeric.floor() == XSD.double("-INF")
      assert XSD.double("NAN") |> Numeric.floor() == XSD.double("NAN")
    end

    test "with xsd:float" do
      assert XSD.float(10.5) |> Numeric.floor() == XSD.float("10")
      assert XSD.float(-10.5) |> Numeric.floor() == XSD.float("-11")

      assert XSD.float("INF") |> Numeric.floor() == XSD.float("INF")
      assert XSD.float("-INF") |> Numeric.floor() == XSD.float("-INF")
      assert XSD.float("NAN") |> Numeric.floor() == XSD.float("NAN")
    end

    test "with xsd:decimal" do
      assert XSD.decimal(10.5) |> Numeric.floor() == XSD.decimal("10")
      assert XSD.decimal(-10.5) |> Numeric.floor() == XSD.decimal("-11")
    end

    test "with derived numerics" do
      assert XSD.byte(42) |> Numeric.floor() == XSD.byte(42)
      assert XSD.non_positive_integer(-42) |> Numeric.floor() == XSD.non_positive_integer(-42)
      assert DoubleUnitInterval.new(0.14) |> Numeric.floor() == XSD.double("0")
      assert DoubleUnitInterval.new(0.4) |> Numeric.floor() == XSD.double("0")
      assert FloatUnitInterval.new(0.5) |> Numeric.floor() == XSD.float("0")
    end

    test "with invalid numeric literals" do
      assert XSD.integer("-3.14") |> Numeric.floor() == nil
      assert XSD.double("foo") |> Numeric.floor() == nil
      assert XSD.decimal("foo") |> Numeric.floor() == nil
    end

    test "coercion" do
      assert Numeric.floor(-42) == XSD.integer(-42)
      assert Numeric.floor(-3.14) == XSD.double("-4")
      assert Numeric.floor(D.from_float(3.14)) == XSD.decimal("3")
      assert Numeric.floor("foo") == nil
      assert Numeric.floor(:foo) == nil
    end
  end

  test "result_type/3 (type-promotion)" do
    %{
      XSD.Integer => %{
        XSD.Integer            => XSD.Integer,
        XSD.NonPositiveInteger => XSD.Integer,
        XSD.NegativeInteger    => XSD.Integer,
        XSD.Long               => XSD.Integer,
        XSD.Int                => XSD.Integer,
        XSD.Short              => XSD.Integer,
        XSD.Byte               => XSD.Integer,
        XSD.NonNegativeInteger => XSD.Integer,
        XSD.UnsignedLong       => XSD.Integer,
        XSD.UnsignedInt        => XSD.Integer,
        XSD.UnsignedShort      => XSD.Integer,
        XSD.UnsignedByte       => XSD.Integer,
        XSD.PositiveInteger    => XSD.Integer,
        XSD.Decimal            => XSD.Decimal,
        XSD.Float              => XSD.Float,
        XSD.Double             => XSD.Double,
        DecimalUnitInterval    => XSD.Decimal,
        FloatUnitInterval      => XSD.Float,
        DoubleUnitInterval     => XSD.Double,
      },
      XSD.Byte => %{
        XSD.Integer            => XSD.Integer,
        XSD.NonPositiveInteger => XSD.Integer,
        XSD.NegativeInteger    => XSD.Integer,
        XSD.Long               => XSD.Integer,
        XSD.Int                => XSD.Integer,
        XSD.Short              => XSD.Integer,
        XSD.Byte               => XSD.Integer,
        XSD.NonNegativeInteger => XSD.Integer,
        XSD.UnsignedLong       => XSD.Integer,
        XSD.UnsignedInt        => XSD.Integer,
        XSD.UnsignedShort      => XSD.Integer,
        XSD.UnsignedByte       => XSD.Integer,
        XSD.PositiveInteger    => XSD.Integer,
        XSD.Decimal            => XSD.Decimal,
        XSD.Float              => XSD.Float,
        XSD.Double             => XSD.Double,
        DecimalUnitInterval    => XSD.Decimal,
        FloatUnitInterval      => XSD.Float,
        DoubleUnitInterval     => XSD.Double,
      },
      XSD.Decimal => %{
        XSD.Integer            => XSD.Decimal,
        XSD.NonPositiveInteger => XSD.Decimal,
        XSD.NegativeInteger    => XSD.Decimal,
        XSD.Long               => XSD.Decimal,
        XSD.Int                => XSD.Decimal,
        XSD.Short              => XSD.Decimal,
        XSD.Byte               => XSD.Decimal,
        XSD.NonNegativeInteger => XSD.Decimal,
        XSD.UnsignedLong       => XSD.Decimal,
        XSD.UnsignedInt        => XSD.Decimal,
        XSD.UnsignedShort      => XSD.Decimal,
        XSD.UnsignedByte       => XSD.Decimal,
        XSD.PositiveInteger    => XSD.Decimal,
        XSD.Decimal            => XSD.Decimal,
        XSD.Float              => XSD.Float,
        XSD.Double             => XSD.Double,
        DecimalUnitInterval    => XSD.Decimal,
        FloatUnitInterval      => XSD.Float,
        DoubleUnitInterval     => XSD.Double,
      },
      DecimalUnitInterval => %{
        XSD.Integer            => XSD.Decimal,
        XSD.NonPositiveInteger => XSD.Decimal,
        XSD.NegativeInteger    => XSD.Decimal,
        XSD.Long               => XSD.Decimal,
        XSD.Int                => XSD.Decimal,
        XSD.Short              => XSD.Decimal,
        XSD.Byte               => XSD.Decimal,
        XSD.NonNegativeInteger => XSD.Decimal,
        XSD.UnsignedLong       => XSD.Decimal,
        XSD.UnsignedInt        => XSD.Decimal,
        XSD.UnsignedShort      => XSD.Decimal,
        XSD.UnsignedByte       => XSD.Decimal,
        XSD.PositiveInteger    => XSD.Decimal,
        XSD.Decimal            => XSD.Decimal,
        XSD.Float              => XSD.Float,
        XSD.Double             => XSD.Double,
        DecimalUnitInterval    => XSD.Decimal,
        FloatUnitInterval      => XSD.Float,
        DoubleUnitInterval     => XSD.Double,
      },
      XSD.Float => %{
        XSD.Integer            => XSD.Float,
        XSD.NonPositiveInteger => XSD.Float,
        XSD.NegativeInteger    => XSD.Float,
        XSD.Long               => XSD.Float,
        XSD.Int                => XSD.Float,
        XSD.Short              => XSD.Float,
        XSD.Byte               => XSD.Float,
        XSD.NonNegativeInteger => XSD.Float,
        XSD.UnsignedLong       => XSD.Float,
        XSD.UnsignedInt        => XSD.Float,
        XSD.UnsignedShort      => XSD.Float,
        XSD.UnsignedByte       => XSD.Float,
        XSD.PositiveInteger    => XSD.Float,
        XSD.Decimal            => XSD.Float,
        XSD.Float              => XSD.Float,
        XSD.Double             => XSD.Double,
        DecimalUnitInterval    => XSD.Float,
        FloatUnitInterval      => XSD.Float,
        DoubleUnitInterval     => XSD.Double,
      },
      FloatUnitInterval => %{
        XSD.Integer            => XSD.Float,
        XSD.NonPositiveInteger => XSD.Float,
        XSD.NegativeInteger    => XSD.Float,
        XSD.Long               => XSD.Float,
        XSD.Int                => XSD.Float,
        XSD.Short              => XSD.Float,
        XSD.Byte               => XSD.Float,
        XSD.NonNegativeInteger => XSD.Float,
        XSD.UnsignedLong       => XSD.Float,
        XSD.UnsignedInt        => XSD.Float,
        XSD.UnsignedShort      => XSD.Float,
        XSD.UnsignedByte       => XSD.Float,
        XSD.PositiveInteger    => XSD.Float,
        XSD.Decimal            => XSD.Float,
        XSD.Float              => XSD.Float,
        XSD.Double             => XSD.Double,
        DecimalUnitInterval    => XSD.Float,
        FloatUnitInterval      => XSD.Float,
        DoubleUnitInterval     => XSD.Double,
      },
      XSD.Double => %{
        XSD.Integer            => XSD.Double,
        XSD.NonPositiveInteger => XSD.Double,
        XSD.NegativeInteger    => XSD.Double,
        XSD.Long               => XSD.Double,
        XSD.Int                => XSD.Double,
        XSD.Short              => XSD.Double,
        XSD.Byte               => XSD.Double,
        XSD.NonNegativeInteger => XSD.Double,
        XSD.UnsignedLong       => XSD.Double,
        XSD.UnsignedInt        => XSD.Double,
        XSD.UnsignedShort      => XSD.Double,
        XSD.UnsignedByte       => XSD.Double,
        XSD.PositiveInteger    => XSD.Double,
        XSD.Decimal            => XSD.Double,
        XSD.Float              => XSD.Double,
        XSD.Double             => XSD.Double,
        DecimalUnitInterval    => XSD.Double,
        FloatUnitInterval      => XSD.Double,
        DoubleUnitInterval     => XSD.Double,
      },
      DoubleUnitInterval => %{
        XSD.Integer            => XSD.Double,
        XSD.NonPositiveInteger => XSD.Double,
        XSD.NegativeInteger    => XSD.Double,
        XSD.Long               => XSD.Double,
        XSD.Int                => XSD.Double,
        XSD.Short              => XSD.Double,
        XSD.Byte               => XSD.Double,
        XSD.NonNegativeInteger => XSD.Double,
        XSD.UnsignedLong       => XSD.Double,
        XSD.UnsignedInt        => XSD.Double,
        XSD.UnsignedShort      => XSD.Double,
        XSD.UnsignedByte       => XSD.Double,
        XSD.PositiveInteger    => XSD.Double,
        XSD.Decimal            => XSD.Double,
        XSD.Float              => XSD.Double,
        XSD.Double             => XSD.Double,
        DecimalUnitInterval    => XSD.Double,
        FloatUnitInterval      => XSD.Double,
        DoubleUnitInterval     => XSD.Double,
      },
    }
    |> Enum.each(fn {left, right_result} ->
      Enum.each(right_result, fn {right, result} ->
        assert Numeric.result_type(:+, left, right) == result
      end)
    end)
  end
end
